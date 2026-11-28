import Foundation

/// Candidate adapter boundary; use a fresh controller for each generation.
/// Caller must establish OS quiescence before retirement.
@MainActor final class PictureInPictureControllerBinding {
    private let coordinator: PictureInPictureAudioCoordinator
    private var controller: AnyObject?
    private var generation: UUID?
    private var readinessDeadline: UUID?
    private final class RetiredReference {
        weak var instance: AnyObject?
        init(_ instance: AnyObject) { self.instance = instance }
    }
    private var retired: [ObjectIdentifier: RetiredReference] = [:]
    private func pruneRetired() {
        retired = retired.filter { $0.value.instance != nil }
    }
    init(coordinator: PictureInPictureAudioCoordinator) { self.coordinator = coordinator }
    func bind(_ instance: AnyObject) throws -> Bool {
        guard controller == nil else { return false }
        pruneRetired()
        guard retired[ObjectIdentifier(instance)]?.instance !== instance,
              let id = try coordinator.prepare() else { return false }
        controller = instance
        generation = id
        return true
    }
    private func id(for instance: AnyObject) -> UUID? {
        guard controller === instance else { return nil }
        return generation
    }
    /// A queued timeout must match both its controller and its most recent ticket.
    /// The adapter still owns cancellation of the actual DispatchWorkItem.
    func armDeadline(_ instance: AnyObject) -> UUID? {
        guard id(for: instance) != nil, coordinator.phase == .prepared || coordinator.phase == .starting else { return nil }
        let ticket = UUID()
        readinessDeadline = ticket
        return ticket
    }
    func invalidateDeadline(_ instance: AnyObject) {
        guard id(for: instance) != nil else { return }
        readinessDeadline = nil
    }
    func deadlineExpired(_ instance: AnyObject, ticket: UUID) -> Bool {
        guard id(for: instance) != nil, readinessDeadline == ticket else { return false }
        readinessDeadline = nil
        return cancel(instance)
    }
    func willStart(_ instance: AnyObject) -> Bool {
        guard let id = id(for: instance) else { return false }
        return coordinator.willStart(id)
    }
    func didStart(_ instance: AnyObject) -> PictureInPictureLifecyclePolicy.StartResult {
        guard let id = id(for: instance) else { return .ignored }
        let result = coordinator.didStart(id)
        if result == .accepted { readinessDeadline = nil }
        return result
    }
    func cancel(_ instance: AnyObject) -> Bool {
        guard let id = id(for: instance) else { return false }
        readinessDeadline = nil
        return coordinator.cancel(id)
    }
    /// Call only after detaching callbacks and confirming OS quiescence.
    func confirmRetired(_ instance: AnyObject) -> Bool {
        guard let id = id(for: instance), coordinator.confirmRetired(id) else { return false }
        pruneRetired()
        retired[ObjectIdentifier(instance)] = RetiredReference(instance)
        controller = nil
        generation = nil
        readinessDeadline = nil
        return true
    }
}
