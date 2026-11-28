import AVFoundation

/// Best-effort background audio support during an explicitly started CarPlay session.
/// Silent playback is inherited from upstream; it does not guarantee background execution.
/// Respect AVAudioSession interruption advice and stop all recovery on user stop.
/// CarPlayAudio and PiP share this audio session; avoid unnecessary reactivation.
final class BackgroundKeepAlive {
    private var player: AVAudioPlayer?
    private var observers: [NSObjectProtocol] = []
    private var watchdog: Timer?
    private var recovery = BackgroundRecoveryPolicy()
    private var generation = UUID()
    var isRunning: Bool { recovery.isRunning }
    var isActuallyPlaying: Bool { isRunning && recovery.canRecover && player?.isPlaying == true }

    func enteredBackground() { recovery.enteredBackground() }
    func returnedToForeground() {
        recovery.becameActive()
        if !isActuallyPlaying { revive(reason: CWL("返回前台恢复后台音频")) }
    }
    var onLog: ((String) -> Void)?

    private static let lock = NSLock()
    private static var holding = false
    /// True while the keep-alive needs the shared audio session active. Read from any queue.
    static var holdsAudioSession: Bool {
        lock.lock(); defer { lock.unlock() }
        return holding
    }
    private static func setHolding(_ value: Bool) { lock.lock(); holding = value; lock.unlock() }

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }
        Self.setHolding(true)
        guard play(reason: nil) else { Self.setHolding(false); return false }
        recovery.start()
        generation = UUID()
        let token = generation
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
                guard let self, self.generation == token, self.isRunning,
                      let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                if type == .began {
                    self.recovery.beginInterruption()
                    self.player?.pause()
                    self.onLog?(CWL("后台音频已中断"))
                } else if type == .ended {
                    let rawOptions = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                    let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
                    self.recovery.endInterruption(shouldResume: options.contains(.shouldResume))
                    if self.recovery.canRecover {
                        self.revive(reason: CWL("音频中断结束"))
                    } else {
                        self.onLog?(CWL("系统未建议恢复后台音频，请在安全时手动重新启动连接"))
                    }
                }
            },
            center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
                // Every player is invalid after a media services reset; build a new one.
                guard let self, self.generation == token, self.isRunning else { return }
                self.player = nil
                self.revive(reason: CWL("系统媒体服务重置"))
            },
            center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self, self.generation == token, self.isRunning, self.player?.isPlaying != true else { return }
                self.revive(reason: CWL("音频路由变化"))
            }
        ]
        // Catches every other way the player can be stopped (session deactivated, category change).
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            guard let self, self.generation == token, self.isRunning, self.player?.isPlaying != true else { return }
            self.revive(reason: CWL("检测到静音播放已停止"))
        }
        RunLoop.main.add(timer, forMode: .common)
        watchdog = timer
        onLog?(CWL("后台保持已开启"))
        return true
    }

    func stop() {
        guard isRunning else { return }
        recovery.stop()
        generation = UUID()
        Self.setHolding(false)
        watchdog?.invalidate(); watchdog = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        player?.stop()
        player = nil
        CarPlayAudio.endMediaSession()
        onLog?(CWL("后台保持已关闭"))
    }

    private func revive(reason: String) {
        guard isRunning, player?.isPlaying != true,
              recovery.claimRecovery(at: ProcessInfo.processInfo.systemUptime) else { return }
        let ok = play(reason: reason)
        onLog?(ok ? CWL("后台保持已恢复（{1}，第 {2} 次）", [reason, String(recovery.attempts)]) : CWL("后台保持恢复失败（{1}）", [reason]))
        if !ok && recovery.attempts == 3 {
            onLog?(CWL("后台音频恢复次数已达上限"))
        }
    }

    private func play(reason: String?) -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            if reason == nil {
                onLog?(CWL("后台保持准备：类别 {1}，模式 {2}，选项 {3}，路由 {4}", [String(describing: session.category.rawValue), String(describing: session.mode.rawValue), String(describing: session.categoryOptions.rawValue), String(describing: session.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ","))]))
            }
            if session.category != .playback && session.category != .playAndRecord {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            } else if session.category == .playback && !session.categoryOptions.contains(.mixWithOthers) {
                // CarPlay playback may have selected this category without mixing. Silent
                // keep-alive must not request exclusive audio focus from the source iPhone.
                try session.setCategory(.playback, mode: session.mode,
                                        options: session.categoryOptions.union(.mixWithOthers))
            }
            try session.setActive(true)
            let player = try player ?? AVAudioPlayer(data: Self.silentWAV)
            player.numberOfLoops = -1
            player.volume = 0
            self.player = player
            guard player.play() else {
                self.player = nil
                if reason == nil {
                    onLog?(CWL("后台保持开启失败：系统拒绝播放（类别 {1}，模式 {2}，选项 {3}，路由 {4}）", [String(describing: session.category.rawValue), String(describing: session.mode.rawValue), String(describing: session.categoryOptions.rawValue), String(describing: session.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ","))]))
                }
                return false
            }
            return true
        } catch {
            if reason == nil { onLog?(CWL("后台保持开启失败：{1}", [String(describing: error.localizedDescription)])) }
            return false
        }
    }

    /// One second of 8 kHz mono 16-bit silence.
    private static let silentWAV: Data = {
        let rate: UInt32 = 8_000, samples = rate
        let dataBytes = samples * 2
        var wav = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        wav.append(contentsOf: Array("RIFF".utf8)); u32(36 + dataBytes); wav.append(contentsOf: Array("WAVE".utf8))
        wav.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16)
        wav.append(contentsOf: Array("data".utf8)); u32(dataBytes)
        wav.append(Data(count: Int(dataBytes)))
        return wav
    }()

    deinit { stop() }
}
