import Foundation

@main struct DynamicDisplaySmoke {
    static func main() {
        typealias Area = DynamicDisplayState.Area
        let full = Area(id: 0, width: 1280, height: 720)
        let split = Area(id: 1, width: 800, height: 720)
        precondition(DynamicDisplayState(areas: [full, full], initialID: 0) == nil)
        precondition(DynamicDisplayState(areas: [Area(id: 2, width: 0, height: 720)], initialID: 2) == nil)
        precondition(DynamicDisplayState(areas: [full], initialID: 1) == nil)
        var state = DynamicDisplayState(areas: [full, split], initialID: 0)!
        precondition(state.request(areaID: 0) == nil)
        precondition(state.request(areaID: 2) == nil)
        let first = state.request(areaID: 1)!
        precondition(state.active == full)
        precondition(state.request(areaID: 1) == nil)
        precondition(!state.acknowledge(token: first.token, areaID: 0))
        precondition(!state.cancel(token: UUID()))
        precondition(state.cancel(token: first.token))
        precondition(!state.acknowledge(token: first.token, areaID: 1))
        precondition(state.active == full)
        let second = state.request(areaID: 1)!
        precondition(!state.acknowledge(token: first.token, areaID: 1))
        precondition(state.acknowledge(token: second.token, areaID: 1))
        precondition(state.active == split && state.pending == nil)
        precondition(!state.acknowledge(token: second.token, areaID: 1))
        let back = state.request(areaID: 0)!
        precondition(state.acknowledge(token: back.token, areaID: 0))
        precondition(state.active == full)
        print("DynamicDisplaySmoke: passed (offline policy only)")
    }
}
