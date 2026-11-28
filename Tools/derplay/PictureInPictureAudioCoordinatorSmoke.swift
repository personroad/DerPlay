import Foundation

@main struct PictureInPictureAudioCoordinatorSmoke {
    enum Failure: Error { case backend }
    @MainActor static func main() throws {
        var failActivation = true, failRelease = false, releases = 0
        let audio = AudioSessionSerialExecutor(activate: {
            if failActivation { throw Failure.backend }
        }, deactivate: {
            if failRelease { throw Failure.backend }
            releases += 1
        })
        let p = PictureInPictureAudioCoordinator(audio: audio)
        do { _ = try p.prepare(); fatalError("expected failure") } catch Failure.backend {}
        precondition(p.phase == .idle)
        failActivation = false
        let a = try p.prepare()!
        let duplicate = try p.prepare(); precondition(duplicate == nil)
        precondition(p.willStart(a) && p.cancel(a))
        precondition(p.didStart(a) == .stopUnexpected)
        precondition(!p.confirmRetired(UUID()))
        precondition(p.confirmRetired(a) && p.hasPendingRelease)
        failRelease = true
        do { try p.flushIdleRelease(); fatalError("expected failure") } catch Failure.backend {}
        precondition(p.hasPendingRelease)
        failRelease = false
        let retry = try p.flushIdleRelease(); precondition(retry && releases == 1)
        let b = try p.prepare()!
        precondition(!p.confirmRetired(a) && p.didStart(a) == .ignored)
        precondition(p.didStart(b) == .accepted)
        let stream = AudioSessionOwnershipPolicy.Owner.stream(UUID())
        let streamToken = try audio.acquire(stream)
        precondition(p.cancel(b) && p.confirmRetired(b) && !p.hasPendingRelease)
        let ticket = audio.release(stream, token: streamToken)!
        let released = try audio.deactivateIfIdle(ticket: ticket); precondition(released && releases == 2)
        let c = try p.prepare()!
        precondition(p.cancel(c) && p.confirmRetired(c))
        let newToken = try audio.acquire(.keepAlive)
        let stale = try p.flushIdleRelease(); precondition(!stale && releases == 2 && !p.hasPendingRelease)
        let end = audio.release(.keepAlive, token: newToken)!
        let done = try audio.deactivateIfIdle(ticket: end); precondition(done && releases == 3)
        print("PiP audio coordinator smoke PASS: activation failure, retirement, retry, stale generation, concurrent owner, stale idle ticket")
    }
}
