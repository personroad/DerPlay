import Foundation

@main struct AudioSessionOwnerBackendSmoke {
    enum Failure: Error { case simulated }
    static func main() async throws {
        typealias Owner = AudioSessionSerialExecutor.Owner
        var calls: [(Owner, Set<Owner>)] = []
        var fail = false
        let executor = AudioSessionSerialExecutor(activateForOwner: { owner, owners in
            calls.append((owner, owners))
            if fail { throw Failure.simulated }
        }, deactivate: {})
        let stream = Owner.stream(UUID())
        let a = try executor.acquire(stream)
        precondition(calls.last!.0 == stream && calls.last!.1 == [stream])
        fail = true
        do { _ = try await executor.acquireAsync(.keepAlive); preconditionFailure() } catch Failure.simulated {}
        precondition(calls.last!.1 == [stream, .keepAlive])
        fail = false
        let restored = try executor.reactivate(stream, token: a)
        precondition(restored && calls.last!.1 == [stream])
        let b = try await executor.acquireAsync(.keepAlive)
        let c = try executor.acquire(.pictureInPicture)
        precondition(calls.last!.0 == .pictureInPicture && calls.last!.1 == [stream, .keepAlive, .pictureInPicture])
        let count = calls.count
        let stale = try await executor.reactivateAsync(stream, token: UUID())
        precondition(!stale && calls.count == count)
        precondition(executor.releaseDetailed(stream, token: a) == .retainedByOtherOwners)
        let recovered = try await executor.reactivateAsync(.keepAlive, token: b)
        precondition(recovered && calls.last!.1 == [.keepAlive, .pictureInPicture])
        precondition(executor.releaseDetailed(.pictureInPicture, token: c) == .retainedByOtherOwners)
        guard case .idle(let ticket) = executor.releaseDetailed(.keepAlive, token: b) else { preconditionFailure() }
        let stopped = try executor.deactivateIfIdle(ticket: ticket)
        precondition(stopped)
        print("AudioSessionOwnerBackendSmoke PASS: owner context, prospective/live claims, failed acquisition, stale token, release")
    }
}
