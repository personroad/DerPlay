import Foundation
@main struct Smoke {
    static func main() {
        var p = DerPlayNetworkRecoveryPolicy()
        func sample(_ address: String?, _ active: Bool = true) -> DerPlayNetworkRecoveryPolicy.Action { p.sample(address: address, active: active) }
        assert(sample("a") == .none && sample("b") == .none)
        assert(sample(nil) == .none && sample("a") == .none)
        for attempt in 0..<3 {
            for _ in 0..<3 { assert(sample(nil) == .none) }
            assert(sample("a") == .none)
            assert(sample("b") == .none)
            assert(sample("b", false) == .none)
            assert(sample("b") == .none && sample("b") == .none)
            assert(sample("b") == (attempt < 2 ? .retry : .exhausted))
        }
        assert(p.attempts == 2)
        p = DerPlayNetworkRecoveryPolicy()
        for _ in 0..<3 { assert(sample(nil) == .none) }
        p.stop()
        for _ in 0..<4 { assert(sample("a") == .none) }
        var runtime = DerPlayRuntimeNetworkRecoveryPolicy()
        runtime.start(pathSatisfied: true)
        assert(runtime.pathChanged(isSatisfied: false, at: 1) == .outageBegan)
        // A short path flap is not enough evidence to restart a live session.
        assert(runtime.pathChanged(isSatisfied: true, at: 2) == .none)
        assert(!runtime.hasPendingRecovery)

        assert(runtime.pathChanged(isSatisfied: false, at: 10) == .outageBegan)
        assert(runtime.pathChanged(isSatisfied: true, at: 14) == .restoredAfterOutage)
        assert(runtime.hasPendingRecovery)
        assert(runtime.delayUntilEligible(at: 14, videoAge: 0) == 10)
        assert(!runtime.claimRecovery(at: 24, videoAge: 9.9, hasAddress: true, appActive: true))
        assert(!runtime.claimRecovery(at: 24, videoAge: 10, hasAddress: false, appActive: true))
        assert(!runtime.claimRecovery(at: 24, videoAge: 10, hasAddress: true, appActive: false))
        assert(runtime.claimRecovery(at: 24, videoAge: 10, hasAddress: true, appActive: true))
        assert(runtime.attempts == 1 && !runtime.hasPendingRecovery)

        assert(runtime.pathChanged(isSatisfied: false, at: 30) == .outageBegan)
        assert(runtime.pathChanged(isSatisfied: true, at: 34) == .restoredAfterOutage)
        assert(runtime.claimRecovery(at: 44, videoAge: 12, hasAddress: true, appActive: true))
        assert(runtime.attempts == 2)
        assert(runtime.pathChanged(isSatisfied: false, at: 50) == .outageBegan)
        assert(runtime.pathChanged(isSatisfied: true, at: 54) == .restoredAfterOutage)
        assert(!runtime.claimRecovery(at: 64, videoAge: 20, hasAddress: true, appActive: true))

        assert(runtime.noteAddressChanged(at: 70) == .restoredAfterOutage)
        assert(runtime.delayUntilEligible(at: 70, videoAge: 20) == 10)
        runtime.stop()
        assert(!runtime.hasPendingRecovery && !runtime.isRunning)
        assert(!runtime.claimRecovery(at: 90, videoAge: 90, hasAddress: true, appActive: true))
        print("Network startup and runtime recovery policy smoke passed")
    }
}
