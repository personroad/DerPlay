import Foundation

/// Offline policy only. A missing IP is not proof of a particular Wi-Fi identity.
struct DerPlayNetworkRecoveryPolicy {
    enum Action: Equatable { case none, retry, exhausted }
    private(set) var attempts = 0
    private var missing = 0
    private var stable = 0
    private var candidate: String?
    private var armed = false
    private var stopped = false

    mutating func stop() { stopped = true; armed = false; candidate = nil; stable = 0; missing = 0 }

    /// Called on consecutive samples from an explicitly started session.
    /// Never initiate recovery for a resolution change or a mere address change.
    mutating func sample(address: String?, active: Bool) -> Action {
        guard !stopped else { return .none }
        guard active else { missing = 0; stable = 0; candidate = nil; return .none }
        guard let address, !address.isEmpty else {
            missing = min(missing + 1, 3); stable = 0; candidate = nil
            if missing == 3 { armed = true }
            return .none
        }
        missing = 0
        guard armed else { return .none }
        if candidate != address { candidate = address; stable = 0 }
        stable += 1
        guard stable >= 3 else { return .none }
        armed = false; stable = 0; candidate = nil
        guard attempts < 2 else { stopped = true; return .exhausted }
        attempts += 1
        return .retry
    }
}

/// Runtime recovery gate for an already-established instrument Wi-Fi session.
/// A path transition alone never restarts a session: the path must recover and
/// the video stream must remain stale for a further bounded interval.
struct DerPlayRuntimeNetworkRecoveryPolicy {
    enum Event: Equatable { case none, outageBegan, restoredAfterOutage }

    private(set) var isRunning = false
    private(set) var attempts = 0
    private var pathSatisfied: Bool?
    private var outageStartedAt: TimeInterval?
    private var restoredAt: TimeInterval?

    var hasPendingRecovery: Bool { restoredAt != nil }

    mutating func start(pathSatisfied: Bool) {
        self = Self()
        isRunning = true
        self.pathSatisfied = pathSatisfied
    }

    mutating func stop() { self = Self() }

    mutating func pathChanged(isSatisfied: Bool, at now: TimeInterval) -> Event {
        guard isRunning, now.isFinite else { return .none }
        let previous = pathSatisfied
        pathSatisfied = isSatisfied
        guard let previous, previous != isSatisfied else { return .none }
        if previous && !isSatisfied {
            outageStartedAt = now
            restoredAt = nil
            return .outageBegan
        }
        guard let outageStartedAt else { return .none }
        let outageDuration = now - outageStartedAt
        self.outageStartedAt = nil
        guard outageDuration >= 3 else { return .none }
        restoredAt = now
        return .restoredAfterOutage
    }

    /// A changed local Wi-Fi address after backgrounding is a recovery candidate,
    /// but still requires a stale video stream before any restart is allowed.
    mutating func noteAddressChanged(at now: TimeInterval) -> Event {
        guard isRunning, pathSatisfied == true, now.isFinite else { return .none }
        restoredAt = now
        outageStartedAt = nil
        return .restoredAfterOutage
    }

    func delayUntilEligible(at now: TimeInterval, videoAge: TimeInterval) -> TimeInterval? {
        guard isRunning, let restoredAt, now.isFinite, videoAge.isFinite else { return nil }
        return max(0, max(10 - (now - restoredAt), 10 - videoAge))
    }

    mutating func claimRecovery(at now: TimeInterval, videoAge: TimeInterval,
                                hasAddress: Bool, appActive: Bool) -> Bool {
        guard isRunning, pathSatisfied == true, restoredAt != nil,
              now.isFinite, videoAge.isFinite, appActive, hasAddress,
              now - (restoredAt ?? now) >= 10, videoAge >= 10, attempts < 2 else { return false }
        attempts += 1
        restoredAt = nil
        return true
    }

    mutating func cancelPendingRecovery() { restoredAt = nil }
}

/// Conservative AirPlay item recovery. It never changes the selected system route;
/// it only reloads the existing HLS item on the existing AVPlayer instance.
/// A fresh source-frame signal is required so an upstream video outage is not
/// mistaken for a broken AVPlayer item.
struct DerPlayAirPlayRecoveryPolicy {
    enum Action: Equatable {
        case none
        case reloadCurrentItem(attempt: Int)
        case exhausted
    }

    private(set) var attempts = 0
    private var lastAttempt: TimeInterval?
    private var exhaustionReported = false

    mutating func reset() {
        self = Self()
    }

    mutating func evaluate(
        at now: TimeInterval,
        appIsActive: Bool,
        externalPlaybackIsActive: Bool,
        sourceFramesAreFresh: Bool,
        itemFailed: Bool,
        playbackWaitIsProlonged: Bool,
        timelineIsStalled: Bool,
        explicitlyPaused: Bool
    ) -> Action {
        guard now.isFinite, appIsActive, externalPlaybackIsActive,
              sourceFramesAreFresh, !explicitlyPaused else { return .none }
        guard itemFailed || playbackWaitIsProlonged || timelineIsStalled else { return .none }
        if let lastAttempt, now - lastAttempt < 20 { return .none }
        guard attempts < 2 else {
            guard !exhaustionReported else { return .none }
            exhaustionReported = true
            return .exhausted
        }
        attempts += 1
        lastAttempt = now
        return .reloadCurrentItem(attempt: attempts)
    }
}

/// Throttles foreground AirPlay buffer diagnostics without influencing playback.
/// Buffer depth is sampled separately from state flags so the two-second health
/// timer does not emit a log line for every small buffer fluctuation.
struct DerPlayAirPlayBufferTelemetry {
    struct Snapshot {
        let isEmpty: Bool
        let likelyToKeepUp: Bool
        let isFull: Bool
        let bufferedAheadSeconds: Double?

        var stateKey: String {
            "\(isEmpty)|\(likelyToKeepUp)|\(isFull)"
        }

        var bufferedAheadBucket: Int? {
            guard let value = bufferedAheadSeconds, value.isFinite else { return nil }
            return Int((min(60, max(0, value)) * 2).rounded())
        }
    }

    private var lastStateKey: String?
    private var lastLoggedAt: TimeInterval?

    mutating func reset() {
        lastStateKey = nil
        lastLoggedAt = nil
    }

    /// Log immediately on a meaningful buffer-state transition, otherwise at
    /// most once every ten seconds. Non-finite clocks are ignored.
    mutating func shouldLog(_ snapshot: Snapshot, at now: TimeInterval) -> Bool {
        guard now.isFinite else { return false }
        let stateChanged = snapshot.stateKey != lastStateKey
        let intervalElapsed = lastLoggedAt.map { now < $0 || now - $0 >= 10 } ?? true
        guard stateChanged || intervalElapsed else { return false }
        lastStateKey = snapshot.stateKey
        lastLoggedAt = now
        return true
    }
}


/// Local AVPlayer seekable-window measurement, not receiver display latency.
enum DerPlayAirPlayLiveEdge {
    static func lagSeconds(position: Double, ranges: [(start: Double, end: Double)]) -> Double? {
        guard position.isFinite else { return nil }
        let valid = ranges.filter { $0.start.isFinite && $0.end.isFinite && $0.end > $0.start }
        // A stale playhead outside every current seekable interval is not a reliable estimate.
        guard valid.contains(where: { $0.start <= position && position <= $0.end }),
              let edge = valid.map({ $0.end }).max() else { return nil }
        let lag = edge - position
        return lag.isFinite ? lag : nil
    }
}

/// Diagnostic only: compare consecutive local playhead samples with monotonic
/// elapsed time. An item replacement, pause, route loss or background resets
/// the comparison; a jump is not evidence of A/V skew or remote rendering.
struct DerPlayAirPlayTimelineTelemetry {
    enum Jump: String { case backward, forward }
    private var previous: (position: Double, uptime: TimeInterval)?
    private var lastLoggedAt: TimeInterval?

    mutating func reset() { self = Self() }

    mutating func sample(position: Double, at now: TimeInterval, rate: Double) -> Jump? {
        guard position.isFinite, now.isFinite, rate.isFinite, rate > 0 else {
            reset(); return nil
        }
        let old = previous
        previous = (position, now)
        guard let old else { return nil }
        let elapsed = now - old.uptime
        guard elapsed > 0, elapsed <= 6 else { return nil }
        let delta = position - old.position
        guard delta.isFinite else { return nil }
        let jump: Jump
        if delta < -0.5 { jump = .backward }
        else if delta - elapsed * rate > 2 { jump = .forward }
        else { return nil }
        guard lastLoggedAt.map({ now < $0 || now - $0 >= 10 }) ?? true else { return nil }
        lastLoggedAt = now
        return jump
    }
}
