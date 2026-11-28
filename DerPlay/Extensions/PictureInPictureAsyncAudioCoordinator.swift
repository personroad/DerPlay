import Foundation

/// Offline candidate; sole PiP owner on this executor. Controller creation
/// must occur only after preparation succeeds.
@MainActor final class PictureInPictureAsyncAudioCoordinator {
    enum CoordinatorError: Error { case unexpectedRelease }
    private let audio: AudioSessionSerialExecutor
    private var lifecycle = PictureInPictureLifecyclePolicy()
    private var claim: UUID?
    private var busy = false
    private var cancelled = false
    private(set) var isPreparing = false
    private var pendingIdle: UUID?
    init(audio: AudioSessionSerialExecutor) { self.audio = audio }
    var phase: PictureInPictureLifecyclePolicy.Phase { lifecycle.phase }
    var hasPendingRelease: Bool { pendingIdle != nil }
    func cancelPreparation() { if isPreparing { cancelled = true } }
    func prepare() async throws -> UUID? {
        guard !busy, phase == .idle, claim == nil else { return nil }
        try Task.checkCancellation()
        busy = true; isPreparing = true; cancelled = false
        defer { busy = false; isPreparing = false }
        claim = try await audio.acquireAsync(.pictureInPicture)
        pendingIdle = nil
        if cancelled || Task.isCancelled { try await releaseClaim(); return nil }
        return lifecycle.prepare()
    }
    func willStart(_ id: UUID) -> Bool { lifecycle.willStart(id) }
    func didStart(_ id: UUID) -> PictureInPictureLifecyclePolicy.StartResult { lifecycle.didStart(id) }
    func cancel(_ id: UUID) -> Bool { lifecycle.cancel(id) }
    /// Adapter must establish controller quiescence and detach callbacks first.
    func confirmRetired(_ id: UUID) async throws -> Bool {
        guard !busy, lifecycle.retired(id) else { return false }
        busy = true
        defer { busy = false }
        try await releaseClaim()
        return true
    }
    private func releaseClaim() async throws {
        guard let token = claim else { throw CoordinatorError.unexpectedRelease }
        switch await audio.releaseAsync(.pictureInPicture, token: token) {
        case .idle(let ticket): pendingIdle = ticket
        case .retainedByOtherOwners: pendingIdle = nil
        case .invalidToken, .reentrantRejected: throw CoordinatorError.unexpectedRelease
        }
        claim = nil
    }
    func flushIdleRelease() async throws -> Bool {
        guard !busy, let ticket = pendingIdle else { return false }
        busy = true
        defer { busy = false }
        let result = try await audio.deactivateIfIdleAsync(ticket: ticket)
        pendingIdle = nil
        return result
    }
}
