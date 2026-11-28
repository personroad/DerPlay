import Foundation

@main struct PictureInPictureLifecycleSmoke {
    static func main() {
        var p = PictureInPictureLifecyclePolicy()
        precondition(!p.requiresAudio)
        let a = p.prepare()!
        precondition(p.requiresAudio && p.phase == .prepared)
        precondition(p.prepare() == nil)
        precondition(p.willStart(a))
        precondition(!p.willStart(a))
        precondition(p.cancel(a) && p.requiresAudio)
        precondition(p.prepare() == nil)
        precondition(p.didStart(a) == .stopUnexpected)
        precondition(p.retired(a) && !p.requiresAudio)
        let b = p.prepare()!
        precondition(a != b)
        precondition(p.didStart(a) == .ignored)
        precondition(!p.cancel(a) && !p.retired(a))
        precondition(p.didStart(b) == .accepted && p.phase == .active)
        precondition(!p.retired(b))
        precondition(p.didStart(b) == .ignored)
        precondition(p.cancel(b) && p.requiresAudio)
        precondition(p.retired(b) && p.phase == .idle)
        let c = p.prepare()!
        precondition(p.cancel(c) && p.retired(c))
        print("PiP lifecycle smoke PASS (prepared, active, draining, stale generation)")
    }
}
