// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import AVFoundation
import CryptoKit
import Darwin
import Network

private final class AudioDatagramPort {
    let port: UInt16
    private var source: DispatchSourceRead?
    var onPacket: ((Data) -> Void)?
    init(queue: DispatchQueue, peerAddress: String) throws {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else { throw POSIXError(.EIO) }
        var receiveBuffer: Int32 = 512 * 1024
        setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &receiveBuffer, socklen_t(MemoryLayout<Int32>.size))
        var allowed = in_addr()
        guard inet_pton(AF_INET, peerAddress, &allowed) == 1 else { close(fd); throw ProtocolError.malformed(CWL("音频对端地址")) }
        var address = sockaddr_in(); address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size); address.sin_family = sa_family_t(AF_INET)
        let bound = withUnsafePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) } }
        guard bound == 0, fcntl(fd, F_SETFL, O_NONBLOCK) == 0 else { close(fd); throw POSIXError(.EIO) }
        var count = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &count) } }
        guard named == 0 else { close(fd); throw POSIXError(.EIO) }
        port = UInt16(bigEndian: address.sin_port)
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue); self.source = source
        source.setEventHandler { [weak self] in
            guard let self else { return }
            // Bound the work per dispatch so media cannot starve control traffic.
            var bytes = [UInt8](repeating: 0, count: 65536)
            for _ in 0..<32 {
                var peer = sockaddr_in(); var size = socklen_t(MemoryLayout<sockaddr_in>.size)
                let length = withUnsafeMutablePointer(to: &peer) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { recvfrom(fd, &bytes, 65536, 0, $0, &size) } }
                guard length > 0 else { break }
                guard peer.sin_addr.s_addr == allowed.s_addr else { continue }
                self.onPacket?(Data(bytes.prefix(length)))
            }
        }
        source.setCancelHandler { close(fd) }; source.resume()
    }
    func stop() { source?.cancel(); source = nil; onPacket = nil }
    deinit { stop() }
}

final class CarPlayAudio {
    let dataPort: UInt16
    let controlPort: UInt16
    let format: ReceiverAudioFormat
    let connectionID: UInt64
    private let queue: DispatchQueue
    private let mayLoopBackLocally: Bool
    private let data: AudioDatagramPort
    private let control: AudioDatagramPort
    private let cipher: AudioStream
    // Construct the playback graph only when authenticated audio actually arrives. Creating
    // it during RTSP SETUP can block for seconds while iOS switches the CarPlay audio route.
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private let output: AVAudioFormat
    private let decoder: NativeAudioDecoder
    private var microphone: NativeMicrophone?
    private var queuedFrames = 0
    private var playbackGeneration: UInt64 = 0
    private var blockedMediaRoute = false
    #if os(iOS)
    private var routeObserver: NSObjectProtocol?
    private var lastOutputRoute: [String]?
    #endif
    private var active = true
    // Render queue only: SETUP may construct sockets before committing the stream.
    private var committed = false
    private var reportedDecodedAudio = false
    private var reportedBrowserHandoff = false
    private var playing = false
    private var rejected = 0
    private var firstTimestamp: UInt32?
    private var lastTimestamp: UInt32?
    private var buffering = true
    private var packets = 0
    private var latePackets = 0
    private var overflowPackets = 0
    private var underruns = 0
    private var nextStatistics = 0.0
    private var retryPlaybackAt = 0.0
    private let feedbackLock = NSLock()
    private var renderedSampleTime: UInt32?
    private var browserClock: (rtp: UInt32, host: UInt64)?
    private static let renderQueue = DispatchQueue(label: "TDSCarKit.audio", qos: .userInteractive)
    // Audio decoding never blocks the video/RTSP queue. All streams share this queue.
    private static var playingStreams = 0
    #if os(iOS)
    private static var hasSpeakerOverride = false
    // Render-queue confined: session ownership survives a playback graph reset.
    private static var sessionOwners = Set<ObjectIdentifier>()
    private static var duplexOwners = Set<ObjectIdentifier>()
    private static func requiresDuplex(requestsMicrophone: Bool) -> Bool {
        requestsMicrophone || !duplexOwners.isEmpty || pendingMicrophoneStops > 0 || hasSpeakerOverride
    }
    private static var pendingMicrophoneStops = 0
    private static var deferredEndAfterMicrophoneStop = false
    private static func finishMicrophoneStop() {
        pendingMicrophoneStops -= 1
        guard pendingMicrophoneStops == 0 else { return }
        let releaseOverride = deferredEndAfterMicrophoneStop
        deferredEndAfterMicrophoneStop = false
        restoreMediaCategoryIfNeeded()
        deactivateSessionIfIdle(releaseSpeakerOverride: releaseOverride)
    }
    // Render queue only. Do not change category while a microphone or legacy
    // speaker override still owns the shared session. Never activate a new route here.
    private static func shouldRestoreMediaCategory() -> Bool {
        !sessionOwners.isEmpty && duplexOwners.isEmpty && pendingMicrophoneStops == 0 && !hasSpeakerOverride
    }
    private static func restoreMediaCategoryIfNeeded() {
        // Once the last duplex stream has stopped, a surviving media stream
        // must not inherit its forced speaker route. Preserve the legacy idle
        // replacement behavior when there are no remaining owners.
        guard !sessionOwners.isEmpty, duplexOwners.isEmpty, pendingMicrophoneStops == 0 else { return }
        let session = AVAudioSession.sharedInstance()
        if hasSpeakerOverride {
            do {
                try session.overrideOutputAudioPort(.none)
                hasSpeakerOverride = false
            } catch {
                NSLog("DerPlay R177 speaker override release failed: %@", error.localizedDescription)
                return
            }
        }
        guard shouldRestoreMediaCategory(), session.category == .playAndRecord else { return }
        let options: AVAudioSession.CategoryOptions = BackgroundKeepAlive.holdsAudioSession ? [.mixWithOthers] : []
        do {
            try session.setCategory(.playback, mode: .default, options: options)
        } catch {
            // Keep the existing category on failure; a later stream transition can retry.
            NSLog("DerPlay R171 media category restoration failed: %@", error.localizedDescription)
        }
    }
    private func releaseSessionOwnership() {
        Self.duplexOwners.remove(ObjectIdentifier(self))
        if Self.sessionOwners.remove(ObjectIdentifier(self)) != nil {
            Self.restoreMediaCategoryIfNeeded()
            Self.deactivateSessionIfIdle()
        }
    }
    #endif
    var onLog: ((String) -> Void)?
    var onBrowserAudio: ((AVAudioPCMBuffer, UInt64) -> Void)?
    init(secret: SymmetricKey, peerAddress: String, connectionID: UInt64, format: ReceiverAudioFormat, microphonePort: UInt16? = nil, mayLoopBackLocally: Bool = true) throws {
        if let microphonePort {
            guard microphonePort > 0, !format.isAAC, format.channels == 1 else {
                throw ProtocolError.malformed(CWL("麦克风配置无效"))
            }
        }
        self.mayLoopBackLocally = mayLoopBackLocally
        self.queue = Self.renderQueue; self.connectionID = connectionID; self.format = format
        decoder = try NativeAudioDecoder(format: format)
        output = decoder.output
        cipher = AudioStream(secret: secret, connectionID: connectionID)
        data = try AudioDatagramPort(queue: Self.renderQueue, peerAddress: peerAddress)
        control = try AudioDatagramPort(queue: Self.renderQueue, peerAddress: peerAddress)
        dataPort = data.port; controlPort = control.port
        if let microphonePort {
            microphone = NativeMicrophone(secret: secret, connectionID: connectionID, address: peerAddress, port: microphonePort, format: format)
        }
        data.onPacket = { [weak self] in self?.receive($0) }
        #if os(iOS)
        routeObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(), queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in self?.handleOutputRouteChange() }
        }
        #endif
    }
    deinit {
        #if os(iOS)
        if let routeObserver { NotificationCenter.default.removeObserver(routeObserver) }
        #endif
    }
    func commitPlayback() {
        queue.async { self.commitPlaybackOnQueue() }
    }
    private func commitPlaybackOnQueue() {
        guard active, !committed else { return }
        committed = true
        onLog?("R182: audio admitted")
    }
    private func receive(_ wire: Data) {
        guard active, committed else { return }
        do {
            let packet = try cipher.receive(wire)
            let arrival = DispatchTime.now().uptimeNanoseconds / 1000
            // Decode every accepted compressed packet to preserve the codec's overlap state.
            packets += 1
            if packets == 1 { onLog?("R182: first authenticated audio packet") }
            if let lastTimestamp, Int32(bitPattern: packet.timestamp &- lastTimestamp) <= 0 { latePackets += 1; return }
            lastTimestamp = packet.timestamp
            guard let buffer = try decoder.decode(packet.samples) else { return }
            if !reportedDecodedAudio {
                reportedDecodedAudio = true
                onLog?("R182: first decoded audio buffer")
            }
            if let onBrowserAudio {
                if !reportedBrowserHandoff {
                    reportedBrowserHandoff = true
                    onLog?("R182: first browser audio handoff (not delivery confirmation)")
                }
                onBrowserAudio(buffer, browserTimestamp(packet.timestamp, arrival: arrival))
                return
            }
            #if os(iOS)
            // A route notification is asynchronous. Reconcile the current output before
            // accepting another local media buffer, even if that notification is queued.
            handleOutputRouteChange()
            // Browser forwarding has already returned. Never render ordinary received media
            // into a CarAudio route: it may be this device's own virtual receiver.
            if microphone == nil, shouldGuardCarAudio(AVAudioSession.sharedInstance().currentRoute.outputs) {
                suppressLocalMediaForCarAudio()
                return
            }
            #endif
            let frames = Int(buffer.frameLength)
            guard queuedFrames + frames <= format.sampleRate * 2 else { overflowPackets += 1; return }
            if !playing {
                let now = ProcessInfo.processInfo.systemUptime
                guard now >= retryPlaybackAt else { return }
                retryPlaybackAt = now + 0.5
                #if os(iOS)
                let session = AVAudioSession.sharedInstance()
                let needsDuplexCategory = Self.requiresDuplex(requestsMicrophone: microphone != nil)
                // Allow hands-free Bluetooth without preferring the built-in speaker.
                var options: AVAudioSession.CategoryOptions = needsDuplexCategory ? [.allowBluetooth] : []
                if Self.hasSpeakerOverride { options.insert(.defaultToSpeaker) }
                if BackgroundKeepAlive.holdsAudioSession { options.insert(.mixWithOthers) }
                let category: AVAudioSession.Category = needsDuplexCategory ? .playAndRecord : .playback
                if session.category != category || session.mode != .default || session.categoryOptions != options {
                    try session.setCategory(category, mode: .default, options: options)
                }
                try session.setActive(true)
                Self.sessionOwners.insert(ObjectIdentifier(self))
                if microphone != nil { Self.duplexOwners.insert(ObjectIdentifier(self)) }
                Self.deferredEndAfterMicrophoneStop = false
                if microphone == nil {
                    let outputs = session.currentRoute.outputs
                    // Record the route before starting the graph, not afterward:
                    // a change during engine.start() must invalidate this graph.
                    lastOutputRoute = Self.outputRouteSignature(outputs)
                    if shouldGuardCarAudio(outputs) {
                        suppressLocalMediaForCarAudio()
                        return
                    }
                }
                if microphone != nil, shouldGuardCarAudio(session.currentRoute.outputs) {
                    // In the same-device session CarAudio is our own virtual CarPlay receiver.
                    // Feeding decoded audio back into that route leaves the physical speaker silent.
                    if session.category != .playAndRecord {
                        try session.setCategory(.playAndRecord, mode: .default, options: options.union(.defaultToSpeaker))
                    }
                    do {
                        try session.overrideOutputAudioPort(.speaker)
                        Self.hasSpeakerOverride = true
                        onLog?(CWL("本机音频避开 CarPlay 路由，改用 iPhone 扬声器"))
                    } catch {
                        releaseSessionOwnership()
                        throw error
                    }
                }
                #endif
                let engine: AVAudioEngine
                if let existing = self.engine { engine = existing }
                else {
                    engine = AVAudioEngine()
                    let player = AVAudioPlayerNode()
                    engine.attach(player); engine.connect(player, to: engine.mainMixerNode, format: output)
                    self.engine = engine; self.player = player
                }
                do { try engine.start() } catch {
                    #if os(iOS)
                    releaseSessionOwnership()
                    #endif
                    throw error
                }
                playing = true; Self.playingStreams += 1
                if let microphone {
                    microphone.onLog = onLog
                    DispatchQueue.main.async { microphone.start() }
                }
                firstTimestamp = packet.timestamp
                onLog?(CWL("原生 {1} 播放已开始：{2} Hz，{3} 声道", [String(describing: format.name), String(describing: format.sampleRate), String(describing: format.channels)]))
                #if os(iOS)
                onLog?(CWL("音频输出路由：{1}", [String(describing: AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ", "))]))
                #endif
            }
            #if os(iOS)
            // Reconcile again after session activation and engine startup. The
            // handler may destroy the graph, so obtain the player only afterward.
            handleOutputRouteChange()
            guard playing else { return }
            if microphone == nil, shouldGuardCarAudio(AVAudioSession.sharedInstance().currentRoute.outputs) {
                suppressLocalMediaForCarAudio()
                return
            }
            if blockedMediaRoute {
                blockedMediaRoute = false
                onLog?("R165: local media route available again")
            }
            #endif
            guard let player else { return }
            let generation = playbackGeneration
            queuedFrames += frames
            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                self?.queue.async { [weak self] in
                    guard let self, self.active, self.playbackGeneration == generation else { return }
                    self.queuedFrames = max(0, self.queuedFrames - frames)
                    if self.queuedFrames == 0, !self.buffering {
                        self.player?.pause(); self.buffering = true; self.underruns += 1
                    }
                }
            }
            let prebuffer = format.sampleRate * (format.isAAC ? 180 : 40) / 1000
            if buffering, queuedFrames >= prebuffer {
                player.play(); buffering = false
            }
            updateFeedback()
            let now = ProcessInfo.processInfo.systemUptime
            if now >= nextStatistics {
                nextStatistics = now + 5
                onLog?(CWL("音频状态：数据包={1}，队列={2}ms，欠载={3}，延迟={4}，溢出={5}，拒绝={6}", [String(describing: packets), String(describing: queuedFrames * 1000 / format.sampleRate), String(describing: underruns), String(describing: latePackets), String(describing: overflowPackets), String(describing: rejected)]))
            }

        } catch {
            rejected += 1
            if rejected <= 3 { onLog?(CWL("音频数据包被拒绝：{1}", [String(describing: error.localizedDescription)])) }
        }
    }
    #if os(iOS)
    private func shouldGuardCarAudio(_ outputs: [AVAudioSessionPortDescription]) -> Bool {
        mayLoopBackLocally && outputs.contains(where: { $0.portType == .carAudio })
    }
    private static func outputRouteSignature(_ outputs: [AVAudioSessionPortDescription]) -> [String] {
        outputs.map { $0.portType.rawValue + ":" + $0.uid }.sorted()
    }
    private func handleOutputRouteChange() {
        guard active, committed, microphone == nil, onBrowserAudio == nil else { return }
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        let signature = Self.outputRouteSignature(outputs)
        guard signature != lastOutputRoute else { return }
        lastOutputRoute = signature
        onLog?("R166: media route changed: " + outputs.map { $0.portType.rawValue }.joined(separator: ","))
        if shouldGuardCarAudio(outputs) {
            suppressLocalMediaForCarAudio()
        } else if blockedMediaRoute {
            blockedMediaRoute = false
            retryPlaybackAt = 0
            onLog?("R166: media route unblocked; awaiting fresh audio")
        } else if playing {
            // A new physical output must not replay audio queued for the previous route.
            // Keep the shared session active; rebuild the graph on the next fresh packet.
            resetLocalPlaybackForRouteChange()
            retryPlaybackAt = 0
            onLog?("R167: media route changed; awaiting fresh audio")
        }
    }
    private func suppressLocalMediaForCarAudio() {
        guard !blockedMediaRoute || playing else { return }
        blockedMediaRoute = true
        resetLocalPlaybackForRouteChange()
        // Do not deactivate or override the user's system route here.
        onLog?("R165: local media rendering suppressed on CarAudio; browser forwarding unaffected")
    }
    private func resetLocalPlaybackForRouteChange() {
        playbackGeneration &+= 1
        player?.stop()
        engine?.stop()
        player = nil; engine = nil
        queuedFrames = 0; buffering = true; firstTimestamp = nil
        feedbackLock.lock(); renderedSampleTime = nil; feedbackLock.unlock()
        if playing { playing = false; Self.playingStreams -= 1 }
    }
    #endif
    private func browserTimestamp(_ rtp: UInt32, arrival: UInt64) -> UInt64 {
        if let anchor = browserClock {
            let samples = Int64(Int32(bitPattern: rtp &- anchor.rtp))
            let position = Int64(anchor.host) + samples * 1_000_000 / Int64(format.sampleRate)
            // Keep source timing through packet bursts, and re-anchor after a genuine clock reset.
            if samples >= 0, position >= 0, abs(position - Int64(arrival)) < 500_000 {
                return UInt64(position)
            }
        }
        browserClock = (rtp, arrival)
        return arrival
    }

    private func updateFeedback() {
        guard let firstTimestamp, let player, let render = player.lastRenderTime,
              let position = player.playerTime(forNodeTime: render) else { return }
        let rendered = firstTimestamp &+ UInt32(truncatingIfNeeded: max(0, position.sampleTime))
        feedbackLock.lock()
        renderedSampleTime = rendered
        feedbackLock.unlock()
    }

    func feedback(type: Int, ntp: UInt64) -> [String: Any] {
        // Never wait for AVAudioEngine or an iOS route transition on the RTSP/video queue.
        feedbackLock.lock()
        let rendered = renderedSampleTime
        feedbackLock.unlock()
        var info: [String: Any] = ["type": type, "sampleRate": format.sampleRate]
        if let rendered {
            info["sampleTime"] = NSNumber(value: rendered)
            info["timestamp"] = NSNumber(value: ntp)
            info["streamConnectionID"] = NSNumber(value: connectionID)
        }
        return info
    }

    func stop() {
        // Keep this stream alive until its queued teardown completes; a replacement stream may
        // negotiate immediately, but the render queue always observes the old stop first.
        queue.async { self.stopOnQueue() }
    }
    static func endMediaSession() {
        #if os(iOS)
        renderQueue.async { deactivateSessionIfIdle(releaseSpeakerOverride: true) }
        #endif
    }
    private func stopOnQueue() {
        guard active else { return }; active = false
        committed = false
        #if os(iOS)
        if let routeObserver { NotificationCenter.default.removeObserver(routeObserver) }
        routeObserver = nil; lastOutputRoute = nil
        #endif
        if let microphone {
            #if os(iOS)
            Self.pendingMicrophoneStops += 1
            #endif
            DispatchQueue.main.async {
                microphone.stop()
                #if os(iOS)
                Self.renderQueue.async { Self.finishMicrophoneStop() }
                #endif
            }
        }
        microphone = nil
        data.stop(); control.stop(); player?.stop(); engine?.stop(); queuedFrames = 0
        if playing {
            playing = false; Self.playingStreams -= 1
        }
        #if os(iOS)
        releaseSessionOwnership()
        #endif
    }
    #if os(iOS)
    /// Releases the shared session after the last stream, unless the background keep-alive still
    /// plays in it: deactivating would stop that player too and iOS would suspend the app.
    private static func deactivateSessionIfIdle(releaseSpeakerOverride: Bool = false) {
        guard playingStreams == 0, sessionOwners.isEmpty else { return }
        guard pendingMicrophoneStops == 0 else {
            if releaseSpeakerOverride { deferredEndAfterMicrophoneStop = true }
            return
        }
        let session = AVAudioSession.sharedInstance()
        let keepAlive = BackgroundKeepAlive.holdsAudioSession
        if hasSpeakerOverride {
            // A CarPlay audio format change tears down the old RTP stream. Keep the
            // output route through that replacement so iOS does not renegotiate again.
            guard releaseSpeakerOverride else { return }
            do {
                try session.overrideOutputAudioPort(.none)
                hasSpeakerOverride = false
            } catch {
                // Retain the flag so a later explicit end can retry.
                return
            }
            if !keepAlive {
                try? session.setCategory(.playback, mode: .default, options: [])
            }
        }
        if keepAlive {
            // The silent keep-alive player must not inherit an idle duplex category.
            // Do not deactivate its session or select a physical output.
            if session.category == .playAndRecord ||
                (session.category == .playback && !session.categoryOptions.contains(.mixWithOthers)) {
                do {
                    try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                } catch {
                    NSLog("DerPlay R178 idle duplex category restoration failed: %@", error.localizedDescription)
                }
            }
            return
        }
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
    #endif
}

/// Converts one authenticated RTP payload to native Float32 PCM.
/// AAC payloads are raw access units, not ADTS containers.
final class NativeAudioDecoder {
    let output: AVAudioFormat
    private let format: ReceiverAudioFormat
    private var converter: AVAudioConverter?
    private var compressed: AVAudioFormat?
    init(format: ReceiverAudioFormat) throws {
        self.format = format
        guard let pcmOutput = AVAudioFormat(standardFormatWithSampleRate: Double(format.sampleRate), channels: AVAudioChannelCount(format.channels)) else {
            throw ProtocolError.malformed(CWL("PCM 输出缓冲区"))
        }
        output = pcmOutput
        if format.isAAC || format.isOpus {
            var description = AudioStreamBasicDescription(mSampleRate: Double(format.sampleRate), mFormatID: format.isOpus ? kAudioFormatOpus : kAudioFormatMPEG4AAC,
                mFormatFlags: format.isOpus ? 0 : 2, mBytesPerPacket: 0, mFramesPerPacket: format.isOpus ? UInt32(format.sampleRate / 50) : 1024, mBytesPerFrame: 0,
                mChannelsPerFrame: UInt32(format.channels), mBitsPerChannel: 0, mReserved: 0)
            guard let input = AVAudioFormat(streamDescription: &description), let codec = AVAudioConverter(from: input, to: output) else {
                throw ProtocolError.malformed(CWL("{1} 解码器不可用", [String(describing: format.name)]))
            }
            if format.isAAC { codec.magicCookie = Data(format.sampleRate == 44100 ? [0x12, 0x10] : [0x11, 0x90]) }
            codec.primeMethod = .none
            compressed = input; converter = codec
        }
    }
    func decode(_ payload: Data) throws -> AVAudioPCMBuffer? {
        guard !payload.isEmpty, payload.count <= 65507 else { throw ProtocolError.malformed(CWL("音频载荷大小")) }
        if let converter, let compressed {
            let input = AVAudioCompressedBuffer(format: compressed, packetCapacity: 1, maximumPacketSize: payload.count)
            input.packetCount = 1; input.byteLength = UInt32(payload.count)
            payload.withUnsafeBytes { input.data.copyMemory(from: $0.baseAddress!, byteCount: payload.count) }
            input.packetDescriptions?.pointee = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: format.isOpus ? 0 : 1024, mDataByteSize: UInt32(payload.count))
            guard let pcm = AVAudioPCMBuffer(pcmFormat: output, frameCapacity: format.isOpus ? AVAudioFrameCount(format.sampleRate * 120 / 1000) : 1024) else { throw ProtocolError.malformed(CWL("AAC 输出缓冲区")) }
            var supplied = false, error: NSError?
            let status = converter.convert(to: pcm, error: &error) { _, state in
                if supplied { state.pointee = .noDataNow; return nil }
                supplied = true; state.pointee = .haveData; return input
            }
            if status == .error { throw error ?? NSError(domain: "TDSAudio", code: 1) }
            return pcm.frameLength > 0 ? pcm : nil
        }
        let frameBytes = format.channels * 2
        guard payload.count % frameBytes == 0 else { throw ProtocolError.malformed(CWL("PCM 帧大小")) }
        let frames = payload.count / frameBytes
        guard frames <= format.sampleRate / 4,
              let buffer = AVAudioPCMBuffer(pcmFormat: output, frameCapacity: AVAudioFrameCount(frames)), let planes = buffer.floatChannelData else {
            throw ProtocolError.malformed(CWL("PCM 输出缓冲区"))
        }
        buffer.frameLength = AVAudioFrameCount(frames)
        payload.withUnsafeBytes { raw in
            let bytes = raw.bindMemory(to: UInt8.self)
            for frame in 0..<frames {
                for channel in 0..<format.channels {
                    let index = (frame * format.channels + channel) * 2
                    let sample = Int16(bitPattern: UInt16(bytes[index]) << 8 | UInt16(bytes[index + 1]))
                    planes[channel][frame] = Float(sample) / 32768
                }
            }
        }
        return buffer
    }
}

/// On-demand mono PCM/Opus capture for a negotiated voice uplink. All state is main-thread.
/// Music streams never request microphone permission or activate recording.
private final class NativeMicrophone {
    private let engine = AVAudioEngine()
    private let packetizer: MicrophonePacketizer
    private let connection: NWConnection
    private let rate: Int
    private let format: ReceiverAudioFormat
    private var opusEncoder: NativeOpusEncoder?
    private let slots = DispatchSemaphore(value: 4)
    private var converter: AVAudioConverter?
    private var active = true
    private var installedTap = false
    private var pending = Data()
    private var failures = 0
    var onLog: ((String) -> Void)?
    init(secret: SymmetricKey, connectionID: UInt64, address: String, port: UInt16, format: ReceiverAudioFormat) {
        self.rate = format.sampleRate; self.format = format
        packetizer = MicrophonePacketizer(secret: secret, connectionID: connectionID)
        connection = NWConnection(host: NWEndpoint.Host(address), port: NWEndpoint.Port(rawValue: port)!, using: .udp)
    }
    func start() {
        guard active else { return }
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self, self.active else { return }
                if granted { self.beginCapture() }
                else { self.onLog?(CWL("麦克风权限被拒绝，语音输入不可用")) }
            }
        }
        #else
        onLog?(CWL("麦克风采集需要使用 iPhone/iPad 目标"))
        #endif
    }
    private func beginCapture() {
        do {
            if format.isOpus { opusEncoder = try NativeOpusEncoder(rate: rate) }
            let input = engine.inputNode.outputFormat(forBus: 0)
            guard input.sampleRate > 0, input.channelCount > 0,
                  let output = AVAudioFormat(standardFormatWithSampleRate: Double(rate), channels: 1),
                  let converter = AVAudioConverter(from: input, to: output) else { throw ProtocolError.malformed(CWL("麦克风格式")) }
            self.converter = converter
            connection.start(queue: .main)
            let slots = self.slots
            engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: input) { [weak self] buffer, _ in
                guard slots.wait(timeout: .now()) == .success else { return }
                guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else { slots.signal(); return }
                copy.frameLength = buffer.frameLength
                let source = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
                let target = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
                for index in 0..<source.count {
                    if let src = source[index].mData, let dst = target[index].mData {
                        dst.copyMemory(from: src, byteCount: Int(source[index].mDataByteSize))
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    defer { slots.signal() }
                    guard let self, self.active else { return }
                    self.send(copy)
                }
            }
            installedTap = true
            try engine.start()
            onLog?(CWL("{1} 麦克风已启动：{2} Hz 单声道", [String(describing: format.name), String(describing: rate)]))
        } catch { onLog?(CWL("无法启动麦克风：{1}", [String(describing: error.localizedDescription)])); stop() }
    }
    private func send(_ input: AVAudioPCMBuffer) {
        guard let converter else { return }
        do {
            let capacity = AVAudioFrameCount(ceil(Double(input.frameLength) * Double(rate) / input.format.sampleRate)) + 32
            guard let output = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity) else { return }
            var supplied = false, error: NSError?
            let status = converter.convert(to: output, error: &error) { _, state in
                if supplied { state.pointee = .noDataNow; return nil }
                supplied = true; state.pointee = .haveData; return input
            }
            if status == .error { throw error ?? NSError(domain: "TDSMicrophone", code: 1) }
            guard let samples = output.floatChannelData?[0] else { return }
            for index in 0..<Int(output.frameLength) {
                let scaled = samples[index].isFinite ? max(-32768, min(32767, samples[index] * 32768)) : 0
                let sample = UInt16(bitPattern: Int16(scaled))
                pending.append(UInt8(truncatingIfNeeded: sample >> 8)); pending.append(UInt8(truncatingIfNeeded: sample))
            }
            let frames = rate / 50, bytes = frames * 2
            while pending.count >= bytes {
                let pcm = Data(pending.prefix(bytes))
                pending.removeFirst(bytes)
                let payload: Data
                if let opusEncoder {
                    guard let encoded = try opusEncoder.encode(pcm) else { continue }
                    payload = encoded
                } else { payload = pcm }
                let wire = try packetizer.seal(payload, frames: UInt32(frames))
                connection.send(content: wire, completion: .contentProcessed { [weak self] error in
                    if error != nil { self?.stop() }
                })
            }
        } catch {
            failures += 1
            if failures <= 3 { onLog?(CWL("麦克风转换失败：{1}", [String(describing: error.localizedDescription)])) }
        }
    }
    func stop() {
        guard active else { return }; active = false
        if installedTap { engine.inputNode.removeTap(onBus: 0); installedTap = false }
        engine.stop(); connection.cancel(); converter = nil; pending.removeAll()
    }
}

/// One 20-ms mono voice packet. Uses Apple's codec, with no Ogg/container header.
final class NativeOpusEncoder {
    private let converter: AVAudioConverter
    private let pcm: AVAudioFormat
    private let compressed: AVAudioFormat
    private let frames: Int
    init(rate: Int) throws {
        frames = rate / 50
        pcm = AVAudioFormat(standardFormatWithSampleRate: Double(rate), channels: 1)!
        var description = AudioStreamBasicDescription(mSampleRate: Double(rate), mFormatID: kAudioFormatOpus,
            mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: UInt32(frames), mBytesPerFrame: 0,
            mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0)
        guard let format = AVAudioFormat(streamDescription: &description),
              let codec = AVAudioConverter(from: pcm, to: format) else { throw ProtocolError.malformed(CWL("Opus 编码器不可用")) }
        compressed = format; converter = codec
        converter.primeMethod = .none
        converter.bitRate = rate == 48000 ? 64000 : 32000
    }
    func encode(_ bigEndianPCM: Data) throws -> Data? {
        guard bigEndianPCM.count == frames * 2,
              let input = AVAudioPCMBuffer(pcmFormat: pcm, frameCapacity: AVAudioFrameCount(frames)) else {
            throw ProtocolError.malformed(CWL("Opus 麦克风帧大小"))
        }
        input.frameLength = AVAudioFrameCount(frames)
        bigEndianPCM.withUnsafeBytes { raw in
            let bytes = raw.bindMemory(to: UInt8.self)
            for index in 0..<frames {
                input.floatChannelData![0][index] = Float(Int16(bitPattern: UInt16(bytes[index * 2]) << 8 | UInt16(bytes[index * 2 + 1]))) / 32768
            }
        }
        let packet = AVAudioCompressedBuffer(format: compressed, packetCapacity: 1, maximumPacketSize: 4096)
        var supplied = false, error: NSError?
        let status = converter.convert(to: packet, error: &error) { _, state in
            if supplied { state.pointee = .noDataNow; return nil }
            supplied = true; state.pointee = .haveData; return input
        }
        if status == .error { throw error ?? NSError(domain: "TDSOpus", code: 1) }
        guard packet.packetCount > 0, packet.byteLength > 0 else { return nil }
        return Data(bytes: packet.data, count: Int(packet.byteLength))
    }
}
