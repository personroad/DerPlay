import Foundation

/// Offline integration boundary: transport acknowledgment is not presentation confirmation.
/// The caller must supply independently verified presentation evidence for the same request.
struct DynamicDisplayCoordinator {
    struct Point: Equatable { let x: Double; let y: Double }
    struct Dispatch {
        let token: UUID
        let command: [String: Any]
    }
    private let wire: DynamicDisplayWire
    private var state: DynamicDisplayState
    private var sequence: Int?
    private var accepted = false
    var activeIndex: Int { state.active.id }
    var transitionPending: Bool { state.pending != nil }
    init(wire: DynamicDisplayWire) {
        self.wire = wire
        self.state = DynamicDisplayState(areas: wire.regions.enumerated().map { .init(id: $0.offset, width: $0.element.width, height: $0.element.height) }, initialID: 0)!
    }
    mutating func begin(index: Int) -> Dispatch? {
        guard let command = wire.command(index: index), let request = state.request(areaID: index) else { return nil }
        sequence = nil; accepted = false
        return Dispatch(token: request.token, command: command)
    }
    @discardableResult mutating func bind(token: UUID, cseq: Int) -> Bool {
        guard state.pending?.token == token, sequence == nil, cseq > 0 else { return false }
        sequence = cseq; return true
    }
    @discardableResult mutating func response(cseq: Int, status: Int) -> Bool {
        guard let request = state.pending, sequence == cseq, !accepted, (200...599).contains(status) else { return false }
        if status == 200 { accepted = true; return true }
        _ = cancel(token: request.token); return false
    }
    @discardableResult mutating func confirmPresentation(token: UUID, index: Int) -> Bool {
        guard accepted, state.acknowledge(token: token, areaID: index) else { return false }
        sequence = nil; accepted = false; return true
    }
    @discardableResult mutating func cancel(token: UUID) -> Bool {
        guard state.cancel(token: token) else { return false }
        sequence = nil; accepted = false; return true
    }
    /// Map a point on the aspect-fitted active region into normalized fixed-canvas HID coordinates.
    /// Reject letterbox hits and suspend new touches during transitions; callers release existing contacts first.
    func touch(x: Double, y: Double, viewportWidth: Double, viewportHeight: Double) -> Point? {
        guard !transitionPending, [x,y,viewportWidth,viewportHeight].allSatisfy({ $0.isFinite }), viewportWidth > 0, viewportHeight > 0 else { return nil }
        let r = wire.regions[activeIndex]
        let scale = min(viewportWidth / Double(r.width), viewportHeight / Double(r.height))
        let w = Double(r.width) * scale, h = Double(r.height) * scale
        guard scale.isFinite, w > 0, h > 0 else { return nil }
        let left = (viewportWidth-w)/2, top = (viewportHeight-h)/2
        guard x >= left, x <= left+w, y >= top, y <= top+h else { return nil }
        return Point(x: (Double(r.x)+(x-left)/w*Double(r.width))/Double(wire.width), y: (Double(r.y)+(y-top)/h*Double(r.height))/Double(wire.height))
    }
}
