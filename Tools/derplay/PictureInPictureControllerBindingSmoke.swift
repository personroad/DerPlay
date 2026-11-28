import Foundation
@main struct PictureInPictureControllerBindingSmoke {
    @MainActor static func main() throws {
        let audio = AudioSessionSerialExecutor(activate: {}, deactivate: {})
        let coordinator = PictureInPictureAudioCoordinator(audio: audio)
        let binding = PictureInPictureControllerBinding(coordinator: coordinator)
        let a = NSObject(), b = NSObject()
        let first = try binding.bind(a); precondition(first)
        let duplicate = try binding.bind(b); precondition(!duplicate)
        precondition(!binding.willStart(b) && binding.didStart(b) == .ignored)
        let obsolete = binding.armDeadline(a)!
        let current = binding.armDeadline(a)!
        precondition(!binding.deadlineExpired(a, ticket: obsolete))
        precondition(!binding.deadlineExpired(b, ticket: current))
        precondition(binding.willStart(a))
        precondition(binding.deadlineExpired(a, ticket: current))
        precondition(!binding.deadlineExpired(a, ticket: current))
        precondition(binding.armDeadline(a) == nil)
        precondition(binding.didStart(a) == .stopUnexpected)
        precondition(!binding.confirmRetired(b))
        precondition(binding.confirmRetired(a))
        let reused = try binding.bind(a); precondition(!reused)
        let second = try binding.bind(b); precondition(second)
        precondition(binding.didStart(a) == .ignored && !binding.cancel(a))
        let activeTicket = binding.armDeadline(b)!
        precondition(!binding.deadlineExpired(a, ticket: current))
        binding.invalidateDeadline(a)
        precondition(binding.didStart(b) == .accepted)
        precondition(!binding.deadlineExpired(b, ticket: activeTicket))
        precondition(binding.armDeadline(b) == nil)
        precondition(!binding.confirmRetired(b))
        precondition(binding.cancel(b) && binding.confirmRetired(b))
        let reusedB = try binding.bind(b); precondition(!reusedB)
        weak var weakController: NSObject?
        do {
            let temporary = NSObject()
            weakController = temporary
            let bound = try binding.bind(temporary); precondition(bound)
            precondition(binding.cancel(temporary) && binding.confirmRetired(temporary))
        }
        precondition(weakController == nil)
        for _ in 0..<100 {
            let fresh = NSObject()
            let bound = try binding.bind(fresh); precondition(bound)
            precondition(binding.cancel(fresh) && binding.confirmRetired(fresh))
        }
        let released = try coordinator.flushIdleRelease(); precondition(released)
        print("PiP controller binding smoke PASS")
    }
}
