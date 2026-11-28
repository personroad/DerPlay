import Foundation
@main struct Smoke {
    typealias T = AudioSessionRouteTransaction
    typealias P = AudioSessionRoutePolicy
    enum E: Error { case injected }
    final class Fake {
        var state = P.Snapshot(category: .playback, mixes: false, speakerOverride: false, routeIsCarAudio: false)
        var calls: [String] = []
        var fail: String?; var restoreFails = false; var carAfterActivation = false
        var active = false
        func step(_ s: String) throws { calls.append(s); if fail == s { throw E.injected } }
        var backend: T.Backend<(P.Snapshot,Bool)> {
            .init(capture: { (self.state,self.active) }, snapshot: { self.state }, configure: { c,m,_ in try self.step("configure"); self.state.category=c; self.state.mixes=m }, activate: { try self.step("activate"); self.active=true; self.state.routeIsCarAudio = self.carAfterActivation }, speaker: { s in try self.step("speaker"); self.state.speakerOverride=s }, deactivate: { try self.step("deactivate"); self.active=false }, restore: { s in self.calls.append("restore"); if self.restoreFails { throw E.injected }; (self.state,self.active)=s })
        }
    }
    static func main() throws {
        let id = UUID()
        func run(_ f: Fake, allowed: Bool = true) throws { try T.apply(owners:[.stream(id)], microphones:[id:false], activationAuthorized:allowed, backend:f.backend) }
        let f = Fake(); f.carAfterActivation=true; try run(f)
        precondition(f.state.category == .playAndRecord && f.state.speakerOverride && f.active)
        precondition(f.calls == ["configure","activate","configure","activate","speaker"])
        for step in ["configure","activate","speaker"] {
            let f=Fake(); f.carAfterActivation=true; f.fail=step; let original=f.state
            do { try run(f); preconditionFailure() } catch let e as T.Failure { precondition(e.rollback == nil && f.state == original && !f.active && f.calls.last == "restore") }
        }
        let bad=Fake(); bad.fail="activate"; bad.restoreFails=true
        do { try run(bad); preconditionFailure() } catch let e as T.Failure { precondition(e.rollback != nil) }
        let denied=Fake(); do { try run(denied,allowed:false); preconditionFailure() } catch T.TransactionError.activationNotAuthorized { precondition(denied.calls.isEmpty) }
        let pip=Fake(); try T.apply(owners:[.pictureInPicture],microphones:[:],activationAuthorized:true,backend:pip.backend); precondition(pip.calls == ["activate"])
        let idle=Fake(); idle.state.speakerOverride=true; try T.apply(owners:[],microphones:[:],activationAuthorized:false,backend:idle.backend); precondition(idle.calls.isEmpty)
        try T.apply(owners:[],microphones:[:],endMedia:true,activationAuthorized:false,backend:idle.backend); precondition(idle.calls == ["speaker","deactivate"])
        print("AudioSessionRouteTransactionSmoke PASS: 9 scenarios")
    }
}
