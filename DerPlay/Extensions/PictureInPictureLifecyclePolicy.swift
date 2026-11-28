import Foundation

/// Candidate value model, to be driven on a single UI executor. A generation
/// identifies a distinct controller instance, not a guessed callback attempt.
struct PictureInPictureLifecyclePolicy {
    enum Phase: Equatable { case idle, prepared, starting, active, draining }
    enum StartResult: Equatable { case accepted, stopUnexpected, ignored }
    private(set) var phase: Phase = .idle
    private(set) var generation: UUID?
    var requiresAudio: Bool { phase != .idle }

    mutating func prepare() -> UUID? {
        guard phase == .idle else { return nil }
        let id = UUID()
        generation = id
        phase = .prepared
        return id
    }
    @discardableResult
    mutating func willStart(_ id: UUID) -> Bool {
        guard generation == id, phase == .prepared else { return false }
        phase = .starting
        return true
    }
    mutating func didStart(_ id: UUID) -> StartResult {
        guard generation == id else { return .ignored }
        switch phase {
        case .prepared, .starting: phase = .active; return .accepted
        case .draining: return .stopUnexpected
        default: return .ignored
        }
    }
    /// Cancellation/timeout never assumes that an OS start has stopped.
    /// Retain audio until the adapter confirms controller quiescence.
    @discardableResult
    mutating func cancel(_ id: UUID) -> Bool {
        guard generation == id, phase != .draining else { return false }
        phase = .draining
        return true
    }
    /// Adapter must retire this controller, detach callbacks and confirm no
    /// active or pending OS transition before calling this method.
    @discardableResult
    mutating func retired(_ id: UUID) -> Bool {
        guard generation == id, phase == .draining else { return false }
        generation = nil
        phase = .idle
        return true
    }
}
