import Foundation

@main struct AudioSessionReactivationSmoke {
    enum Failure: Error { case simulated }
    static func main() async throws {
        var activations = 0
        var fail = false
        var executor: AudioSessionSerialExecutor!
        var reentryToken: UUID?
        executor = AudioSessionSerialExecutor(activate: {
            activations += 1
            if let token = reentryToken {
                do { _ = try executor.reactivate(.keepAlive, token: token); preconditionFailure() }
                catch AudioSessionSerialExecutor.ExecutionError.reentrantBackendCall {}
            }
            if fail { throw Failure.simulated }
        }, deactivate: {})
        let a = try executor.acquire(.keepAlive)
        let b = try await executor.acquireAsync(.pictureInPicture)
        reentryToken = a
        let wrong = try executor.reactivate(.keepAlive, token: b)
        let unknown = try await executor.reactivateAsync(.keepAlive, token: UUID())
        precondition(!wrong && !unknown && activations == 2)
        let restored = try executor.reactivate(.keepAlive, token: a)
        precondition(restored && activations == 3)
        fail = true
        do { _ = try await executor.reactivateAsync(.keepAlive, token: a); preconditionFailure() } catch Failure.simulated {}
        fail = false
        let retried = try await executor.reactivateAsync(.keepAlive, token: a)
        precondition(retried && activations == 5)
        let retained = await executor.releaseAsync(.keepAlive, token: a)
        precondition(retained == .retainedByOtherOwners)
        reentryToken = nil
        let new = try executor.acquire(.keepAlive)
        let stale = try await executor.reactivateAsync(.keepAlive, token: a)
        precondition(!stale && activations == 6)
        precondition(executor.releaseDetailed(.keepAlive, token: new) == .retainedByOtherOwners)
        guard case .idle(let ticket) = await executor.releaseAsync(.pictureInPicture, token: b) else { preconditionFailure() }
        let afterRelease = try await executor.reactivateAsync(.pictureInPicture, token: b)
        let idle = try await executor.deactivateIfIdleAsync(ticket: ticket)
        precondition(!afterRelease && idle && activations == 6)
        executor = nil
        print("AudioSessionReactivationSmoke PASS: valid/stale/wrong owner tokens, failure retry, reentry, shared claims, idle ticket")
    }
}
