import Foundation

@main
struct AirPlayRecoverySmoke {
    static func main() {
        var policy = DerPlayAirPlayRecoveryPolicy()
        func expect(_ actual: DerPlayAirPlayRecoveryPolicy.Action,
                    _ expected: DerPlayAirPlayRecoveryPolicy.Action,
                    _ label: String) {
            precondition(actual == expected, "\(label): got \(actual), expected \(expected)")
        }

        expect(policy.evaluate(at: 10, appIsActive: false, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .none, "background must not reload")
        expect(policy.evaluate(at: 10, appIsActive: true, externalPlaybackIsActive: false,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .none, "no external route must not reload")
        expect(policy.evaluate(at: 10, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: false, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .none, "stale source must not reload player")
        expect(policy.evaluate(at: 10, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: true), .none, "explicit pause must not reload")
        expect(policy.evaluate(at: 10, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .reloadCurrentItem(attempt: 1), "first failed-item recovery")
        expect(policy.evaluate(at: 29.9, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .none, "cooldown")
        expect(policy.evaluate(at: 30, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .reloadCurrentItem(attempt: 2), "second recovery")
        expect(policy.evaluate(at: 50, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .exhausted, "bounded exhaustion")
        expect(policy.evaluate(at: 70, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: true,
                               playbackWaitIsProlonged: false, timelineIsStalled: false,
                               explicitlyPaused: false), .none, "exhaustion reported once")
        policy.reset()
        expect(policy.evaluate(at: 80, appIsActive: true, externalPlaybackIsActive: true,
                               sourceFramesAreFresh: true, itemFailed: false,
                               playbackWaitIsProlonged: true, timelineIsStalled: false,
                               explicitlyPaused: false), .reloadCurrentItem(attempt: 1), "prolonged wait recovery")
        print("AirPlay recovery policy smoke passed")
    }
}
