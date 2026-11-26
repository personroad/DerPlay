import Foundation
@main struct ResolutionEvidenceSmoke {
    static func main() {
        typealias S = ResolutionEvidence.Size
        let landscape = S(width: 1918, height: 938)
        let raw = S(width: 1080, height: 2210)
        var model = ResolutionEvidence(active: landscape)
        precondition(model.report(raw: raw) == .insufficientEvidence)
        precondition(model.active == landscape)
        precondition(model.report(raw: raw, verifiedViewport: S(width: 2210, height: 1080)) == .unchanged)
        guard case let .proposed(viewport, token) = model.report(raw: raw, verifiedViewport: raw), viewport == raw else { fatalError("missing proposal") }
        precondition(model.active == landscape)
        precondition(model.confirm(S(width: 526, height: 1080), token: token))
        precondition(model.report(raw: raw) == .unchanged)
        precondition(!model.confirm(landscape, token: token)) // stale proof cannot change presentation
        guard case let .proposed(wide, next) = model.report(raw: raw, verifiedViewport: S(width: 3840, height: 1080)), wide == S(width: 3840, height: 1080) else { fatalError("missing wide proposal") }
        precondition(!model.confirm(wide, token: token))
        precondition(model.report(raw: S(width: 0, height: 1080)) == .invalid)
        precondition(!model.confirm(wide, token: next))
        print("ResolutionEvidenceSmoke PASS: ambiguous raw, verified viewport, portrait, ultrawide, invalid, stale evidence")
    }
}
