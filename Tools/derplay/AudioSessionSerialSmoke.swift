import Foundation
import Dispatch

@main struct AudioSessionSerialSmoke {
    enum Failure: Error { case simulated }
    static func main() throws {
        var activations = 0, deactivations = 0
        var failActivation = false, failDeactivation = false
        let executor = AudioSessionSerialExecutor(activate: {
            activations += 1
            if failActivation { throw Failure.simulated }
        }, deactivate: {
            deactivations += 1
            if failDeactivation { throw Failure.simulated }
        })
        let first = try executor.acquire(.keepAlive)
        do { _ = try executor.acquire(.keepAlive); preconditionFailure() } catch AudioSessionSerialExecutor.ExecutionError.ownerAlreadyOwned {}
        precondition(activations == 1)
        failActivation = true
        do { _ = try executor.acquire(.stream(UUID())); preconditionFailure() } catch Failure.simulated {}
        failActivation = false
        let old = executor.release(.keepAlive, token: first)!
        let pip = try executor.acquire(.pictureInPicture)
        let stale = try executor.deactivateIfIdle(ticket: old)
        precondition(!stale && deactivations == 0)
        let stream = AudioSessionOwnershipPolicy.Owner.stream(UUID())
        let token = try executor.acquire(stream)
        precondition(executor.release(.pictureInPicture, token: pip) == nil)
        let idle = executor.release(stream, token: token)!
        failDeactivation = true
        do { _ = try executor.deactivateIfIdle(ticket: idle); preconditionFailure() } catch Failure.simulated {}
        failDeactivation = false
        let done = try executor.deactivateIfIdle(ticket: idle)
        let duplicate = try executor.deactivateIfIdle(ticket: idle)
        precondition(done && !duplicate && deactivations == 2)
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            let owner = AudioSessionOwnershipPolicy.Owner.stream(UUID())
            let claim = try! executor.acquire(owner)
            if let ticket = executor.release(owner, token: claim) {
                _ = try! executor.deactivateIfIdle(ticket: ticket)
            }
        }
        precondition(activations == 104)
        var nested: AudioSessionSerialExecutor!
        var existing: UUID?
        var idleTicket: UUID?
        var rejected = 0
        func verifyReentry() {
            do { _ = try nested.acquire(.pictureInPicture); preconditionFailure() }
            catch AudioSessionSerialExecutor.ExecutionError.reentrantBackendCall { rejected += 1 }
            catch { preconditionFailure("unexpected error") }
            do { _ = try nested.deactivateIfIdle(ticket: idleTicket ?? UUID()); preconditionFailure() }
            catch AudioSessionSerialExecutor.ExecutionError.reentrantBackendCall { rejected += 1 }
            catch { preconditionFailure("unexpected error") }
            if let existing { precondition(nested.release(.keepAlive, token: existing) == nil) }
        }
        nested = AudioSessionSerialExecutor(activate: verifyReentry, deactivate: verifyReentry)
        existing = try nested.acquire(.keepAlive)
        let second = try nested.acquire(.pictureInPicture)
        precondition(nested.release(.pictureInPicture, token: second) == nil)
        idleTicket = nested.release(.keepAlive, token: existing!)!
        let released = try nested.deactivateIfIdle(ticket: idleTicket!)
        precondition(released && rejected == 6)
        nested = nil
        print("AudioSessionSerialSmoke PASS (100 concurrent iterations; synchronous backend reentry rejected)")
    }
}
