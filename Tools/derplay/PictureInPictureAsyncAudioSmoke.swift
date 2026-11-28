import Foundation
import Dispatch
@main struct PictureInPictureAsyncAudioSmoke {
    enum Failure: Error { case simulated }
    @MainActor static func main() async throws {
        let gate = DispatchSemaphore(value: 0)
        let audio = AudioSessionSerialExecutor(activate: { gate.wait() }, deactivate: {})
        let pip = PictureInPictureAsyncAudioCoordinator(audio: audio)
        for taskCancellation in [false, true] {
            let task = Task { try await pip.prepare() }
            while !pip.isPreparing { await Task.yield() }
            let duplicate = try await pip.prepare()
            precondition(duplicate == nil)
            if taskCancellation { task.cancel() } else { pip.cancelPreparation() }
            gate.signal()
            let result = try await task.value
            precondition(result == nil && pip.phase == .idle && pip.hasPendingRelease)
            let flushed = try await pip.flushIdleRelease()
            precondition(flushed && !pip.hasPendingRelease)
        }
        let normal = AudioSessionSerialExecutor(activate: {}, deactivate: {})
        let p = PictureInPictureAsyncAudioCoordinator(audio: normal)
        let keep = try await normal.acquireAsync(.keepAlive)
        let id = try await p.prepare()!
        precondition(p.willStart(id) && p.didStart(id) == .accepted)
        precondition(p.cancel(id))
        let wrong = try await p.confirmRetired(UUID())
        precondition(!wrong)
        let retired = try await p.confirmRetired(id)
        precondition(retired && !p.hasPendingRelease)
        guard case .idle(let ticket) = await normal.releaseAsync(.keepAlive, token: keep) else { preconditionFailure() }
        let deactivated = try await normal.deactivateIfIdleAsync(ticket: ticket)
        precondition(deactivated)
        // Both coordinators must compete for one PiP claim on the same executor.
        var failures = 1
        var deactivations = 0
        let shared = AudioSessionSerialExecutor(activate: {}, deactivate: {
            deactivations += 1
            if failures > 0 { failures -= 1; throw Failure.simulated }
        })
        let sync = PictureInPictureAudioCoordinator(audio: shared)
        let async = PictureInPictureAsyncAudioCoordinator(audio: shared)
        let syncID = try sync.prepare()!
        do { _ = try await async.prepare(); preconditionFailure() }
        catch AudioSessionSerialExecutor.ExecutionError.pictureInPictureAlreadyOwned {}
        precondition(sync.cancel(syncID) && sync.confirmRetired(syncID))
        let asyncID = try await async.prepare()!
        do { _ = try sync.prepare(); preconditionFailure() }
        catch AudioSessionSerialExecutor.ExecutionError.pictureInPictureAlreadyOwned {}
        precondition(async.cancel(asyncID))
        let done = try await async.confirmRetired(asyncID)
        precondition(done && async.hasPendingRelease)
        do { _ = try await async.flushIdleRelease(); preconditionFailure() } catch Failure.simulated {}
        precondition(async.hasPendingRelease)
        let retried = try await async.flushIdleRelease()
        precondition(retried && !async.hasPendingRelease && deactivations == 2)
        let next = try await async.prepare()!
        precondition(async.cancel(next))
        let ended = try await async.confirmRetired(next)
        precondition(ended)
        let newOwner = try shared.acquire(.keepAlive)
        let stale = try await async.flushIdleRelease()
        precondition(!stale && !async.hasPendingRelease && deactivations == 2)
        guard case .idle(let finalTicket) = shared.releaseDetailed(.keepAlive, token: newOwner) else { preconditionFailure() }
        let final = try shared.deactivateIfIdle(ticket: finalTicket)
        precondition(final && deactivations == 3)
        print("PASS: mutual exclusion, failed deactivation retry, stale idle ticket")
        print("PASS: pending preparation cancellation, task cancellation, duplicate preparation, stale retirement, shared owner protection")
    }
}
