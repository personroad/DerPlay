import Foundation
@main struct DynamicDisplayCoordinatorSmoke {
    static func main() {
        let p = DynamicDisplayWire.landscape(width: 1920, height: 1080, displayUUID: "b7e6c5a0-1111-4000-8000-000000000001")!
        var c = DynamicDisplayCoordinator(wire: p)
        let a = c.begin(index: 2)!
        precondition(c.begin(index: 1) == nil && c.touch(x: 10,y: 10,viewportWidth: 100,viewportHeight: 100) == nil)
        precondition(c.bind(token: a.token,cseq: 41))
        precondition(!c.response(cseq: 40,status: 200))
        precondition(!c.confirmPresentation(token: a.token,index: 2))
        precondition(c.response(cseq: 41,status: 200) && c.activeIndex == 0)
        precondition(!c.confirmPresentation(token: UUID(),index: 2))
        precondition(c.confirmPresentation(token: a.token,index: 2) && c.activeIndex == 2)
        let center = c.touch(x: 480,y: 540,viewportWidth: 960,viewportHeight: 1080)!
        precondition(center.x == 0.25 && center.y == 0.5)
        precondition(c.touch(x: 0,y: 540,viewportWidth: 1920,viewportHeight: 1080) == nil)
        precondition(c.touch(x: .nan,y: 0,viewportWidth: 960,viewportHeight: 1080) == nil)
        let b = c.begin(index: 1)!
        precondition(c.bind(token: b.token,cseq: 42))
        precondition(!c.response(cseq: 42,status: 403) && !c.transitionPending && c.activeIndex == 2)
        let d = c.begin(index: 0)!
        precondition(c.bind(token: d.token,cseq: 43) && c.cancel(token: d.token))
        precondition(!c.response(cseq: 43,status: 200) && !c.confirmPresentation(token: d.token,index: 0))
        print("DynamicDisplayCoordinatorSmoke: passed (offline response correlation and geometry)")
    }
}
