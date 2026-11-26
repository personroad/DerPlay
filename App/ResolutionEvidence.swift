import Foundation

/// Evidence only; a raw panel report is not a measured video viewport.
/// Never used to restart or reconfigure an active session on its own.
struct ResolutionEvidence {
    struct Size: Equatable {
        let width: Int
        let height: Int
        var valid: Bool { (16...16384).contains(width) && (16...16384).contains(height) }
    }
    enum Decision: Equatable {
        case invalid
        case unchanged
        case insufficientEvidence
        case proposed(Size, UUID)
    }
    private(set) var lastRaw: Size?
    private(set) var lastViewport: Size?
    private(set) var active: Size
    private var pending: UUID?
    init(active: Size) { self.active = active }
    mutating func report(raw: Size, verifiedViewport: Size? = nil) -> Decision {
        pending = nil; lastViewport = nil
        guard raw.valid, active.valid else { return .invalid }
        if let viewport = verifiedViewport {
            guard viewport.valid else { return .invalid }
            lastRaw = raw; lastViewport = viewport
            if Self.sameAspect(viewport, active) { return .unchanged }
            let token = UUID(); pending = token
            return .proposed(viewport, token)
        }
        lastRaw = raw
        // Raw reports alone cannot distinguish rotated natural panel dimensions from a real viewport.
        // Never reuse stale verified viewport evidence for a new raw report.
        lastViewport = nil
        return Self.sameAspect(raw, active) ? .unchanged : .insufficientEvidence
    }
    /// Call only after confirmed presentation and synchronized touch geometry.
    mutating func confirm(_ size: Size, token: UUID) -> Bool {
        guard pending == token, size.valid, let viewport = lastViewport, Self.sameAspect(size, viewport) else { return false }
        active = size; pending = nil; return true
    }
    static func sameAspect(_ a: Size, _ b: Size) -> Bool {
        guard a.valid, b.valid else { return false }
        return abs(log(Double(a.width) * Double(b.height) / (Double(a.height) * Double(b.width)))) <= log(1.015)
    }
}
