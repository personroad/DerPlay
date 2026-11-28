import Foundation

/// Pure session policy. AVFoundation and UIKit remain in the owning controller.
/// All mutations by BackgroundKeepAlive occur on the main thread.
struct BackgroundRecoveryPolicy {
    enum State: Equatable { case stopped, permitted, interrupted, deferred }
    private(set) var state: State = .stopped
    private(set) var attempts = 0
    private var lastAttempt: TimeInterval = -.infinity
    private var wasBackgrounded = false

    var isRunning: Bool { state != .stopped }
    var canRecover: Bool { state == .permitted }

    mutating func start() {
        self = Self()
        state = .permitted
    }
    mutating func stop() { self = Self() }
    mutating func beginInterruption() {
        guard isRunning else { return }
        state = .interrupted
    }
    mutating func endInterruption(shouldResume: Bool) {
        guard state == .interrupted else { return }
        state = shouldResume ? .permitted : .deferred
    }
    mutating func enteredBackground() {
        if isRunning { wasBackgrounded = true }
    }
    mutating func becameActive() {
        guard isRunning, wasBackgrounded else { return }
        wasBackgrounded = false
        // Only a genuine background/foreground cycle renews the count. Retain
        // the monotonic cooldown, even across a very rapid return to foreground.
        attempts = 0
    }
    mutating func claimRecovery(at now: TimeInterval) -> Bool {
        guard canRecover, attempts < 3, now.isFinite, now - lastAttempt >= 15 else { return false }
        lastAttempt = now
        attempts += 1
        return true
    }
}
