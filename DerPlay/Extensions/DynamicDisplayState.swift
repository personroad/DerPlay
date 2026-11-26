import Foundation

/// Offline transition policy. Not a wire protocol or an advertised receiver capability.
struct DynamicDisplayState {
    struct Area: Equatable {
        let id: Int
        let width: Int
        let height: Int
        var valid: Bool { id >= 0 && (1...16384).contains(width) && (1...16384).contains(height) }
    }
    struct Request: Equatable {
        let token: UUID
        let area: Area
    }
    private let areas: [Area]
    private(set) var active: Area
    private(set) var pending: Request?

    init?(areas: [Area], initialID: Int) {
        guard !areas.isEmpty, areas.allSatisfy({ $0.valid }),
              Set(areas.map { $0.id }).count == areas.count,
              let initial = areas.first(where: { $0.id == initialID }) else { return nil }
        self.areas = areas
        self.active = initial
    }

    /// Serialized requests; callers coalesce viewport changes separately.
    mutating func request(areaID: Int) -> Request? {
        guard pending == nil, areaID != active.id,
              let area = areas.first(where: { $0.id == areaID }) else { return nil }
        let request = Request(token: UUID(), area: area)
        pending = request
        return request
    }

    /// Caller must establish that the real protocol acknowledged and committed the area.
    /// Mismatched and late events cannot change active geometry.
    @discardableResult mutating func acknowledge(token: UUID, areaID: Int) -> Bool {
        guard let request = pending, request.token == token, request.area.id == areaID else { return false }
        active = request.area
        pending = nil
        return true
    }

    /// On rejection/timeout, keep the existing layout; never request a session restart.
    @discardableResult mutating func cancel(token: UUID) -> Bool {
        guard pending?.token == token else { return false }
        pending = nil
        return true
    }
}
