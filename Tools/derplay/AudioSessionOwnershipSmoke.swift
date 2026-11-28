import Foundation
@main struct AudioSessionOwnershipSmoke {
    static func main() {
        var policy = AudioSessionOwnershipPolicy()
        let initial = policy.idleTicket!
        let pip = policy.acquire(.pictureInPicture)
        precondition(!policy.permitsDeactivation(ticket: initial))
        let keep = policy.acquire(.keepAlive)
        let streamA = AudioSessionOwnershipPolicy.Owner.stream(UUID())
        let streamB = AudioSessionOwnershipPolicy.Owner.stream(UUID())
        let a = policy.acquire(streamA)
        let b = policy.acquire(streamB)
        precondition(policy.release(.keepAlive, token: keep))
        precondition(policy.release(streamA, token: a))
        precondition(policy.release(streamB, token: b))
        precondition(policy.idleTicket == nil)
        precondition(policy.release(.pictureInPicture, token: pip))
        let old = policy.idleTicket!
        precondition(policy.permitsDeactivation(ticket: old))
        let first = policy.acquire(.keepAlive)
        let replacement = policy.acquire(.keepAlive)
        precondition(!policy.release(.keepAlive, token: first))
        precondition(policy.idleTicket == nil)
        precondition(policy.release(.keepAlive, token: replacement))
        precondition(!policy.release(.keepAlive, token: replacement))
        let current = policy.idleTicket!
        precondition(!policy.permitsDeactivation(ticket: old))
        precondition(policy.permitsDeactivation(ticket: current))
        print("AudioSessionOwnershipSmoke PASS")
    }
}
