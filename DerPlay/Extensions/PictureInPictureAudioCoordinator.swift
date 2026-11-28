import Foundation

/// Candidate only. One instance per shared executor; callers must not acquire
/// the PiP owner separately. Controller retirement must be confirmed by adapter.
@MainActor final class PictureInPictureAudioCoordinator {
    private let audio: AudioSessionSerialExecutor
    private var lifecycle = PictureInPictureLifecyclePolicy()
    private var claim: UUID?
    private var pendingIdle: UUID?
    init(audio: AudioSessionSerialExecutor) { self.audio = audio }
    var phase: PictureInPictureLifecyclePolicy.Phase { lifecycle.phase }
    var hasPendingRelease: Bool { pendingIdle != nil }

    func prepare() throws -> UUID? {
        guard phase == .idle else { return nil }
        let token = try audio.acquire(.pictureInPicture)
        claim = token
        pendingIdle = nil // successful acquisition invalidates old idle ticket
        return lifecycle.prepare()
    }
    func willStart(_ id: UUID) -> Bool { lifecycle.willStart(id) }
    func didStart(_ id: UUID) -> PictureInPictureLifecyclePolicy.StartResult { lifecycle.didStart(id) }
    func cancel(_ id: UUID) -> Bool { lifecycle.cancel(id) }

    /// Only after the adapter confirms controller quiescence and detaches callbacks.
    /// Retirement succeeds independently of backend deactivation; failure retains
    /// the ticket for explicit retry (no automatic timer).
    func confirmRetired(_ id: UUID) -> Bool {
        guard let token = claim, lifecycle.retired(id) else { return false }
        claim = nil
        pendingIdle = audio.release(.pictureInPicture, token: token)
        return true
    }
    @discardableResult
    func flushIdleRelease() throws -> Bool {
        guard let ticket = pendingIdle else { return false }
        let result = try audio.deactivateIfIdle(ticket: ticket)
        pendingIdle = nil
        return result
    }
}
