import Foundation

@main struct AudioSessionAsyncSmoke {
    enum Failure: Error { case simulated }
    static func main() async throws {
        let executor = AudioSessionSerialExecutor(activate: {}, deactivate: {})
        let a = try await executor.acquireAsync(.keepAlive)
        do { _ = try await executor.acquireAsync(.keepAlive); preconditionFailure() } catch AudioSessionSerialExecutor.ExecutionError.ownerAlreadyOwned {}
        let stream = AudioSessionOwnershipPolicy.Owner.stream(UUID())
        let streamToken = try await executor.acquireAsync(stream)
        do { _ = try executor.acquire(stream); preconditionFailure() } catch AudioSessionSerialExecutor.ExecutionError.ownerAlreadyOwned {}
        let streamRelease = await executor.releaseAsync(stream, token: streamToken)
        precondition(streamRelease == .retainedByOtherOwners)
        let b = try await executor.acquireAsync(.pictureInPicture)
        let invalid = await executor.releaseAsync(.keepAlive, token: UUID())
        precondition(invalid == .invalidToken)
        let retained = await executor.releaseAsync(.keepAlive, token: a)
        precondition(retained == .retainedByOtherOwners)
        guard case .idle(let ticket) = await executor.releaseAsync(.pictureInPicture, token: b) else { preconditionFailure() }
        let c = try await executor.acquireAsync(.keepAlive)
        let stale = try await executor.deactivateIfIdleAsync(ticket: ticket)
        precondition(!stale)
        guard case .idle(let fresh) = await executor.releaseAsync(.keepAlive, token: c) else { preconditionFailure() }
        let done = try await executor.deactivateIfIdleAsync(ticket: fresh)
        let duplicate = try await executor.deactivateIfIdleAsync(ticket: fresh)
        precondition(done && !duplicate)
        let failing = AudioSessionSerialExecutor(activate: { throw Failure.simulated }, deactivate: {})
        do { _ = try await failing.acquireAsync(.keepAlive); preconditionFailure() } catch Failure.simulated {}
        let retry = AudioSessionSerialExecutor(activate: {}, deactivate: { throw Failure.simulated })
        let claim = try await retry.acquireAsync(.keepAlive)
        guard case .idle(let pending) = await retry.releaseAsync(.keepAlive, token: claim) else { preconditionFailure() }
        for _ in 0..<2 {
            do { _ = try await retry.deactivateIfIdleAsync(ticket: pending); preconditionFailure() } catch Failure.simulated {}
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let owner = AudioSessionOwnershipPolicy.Owner.stream(UUID())
                    let token = try await executor.acquireAsync(owner)
                    switch await executor.releaseAsync(owner, token: token) {
                    case .idle(let t): _ = try await executor.deactivateIfIdleAsync(ticket: t)
                    case .retainedByOtherOwners: break
                    default: preconditionFailure()
                    }
                }
            }
            try await group.waitForAll()
        }
        print("AudioSessionAsyncSmoke PASS (100 async tasks; explicit release outcomes; stale tickets; backend failures)")
    }
}
