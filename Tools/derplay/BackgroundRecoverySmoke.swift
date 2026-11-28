import Foundation

@main struct Smoke {
    static func main() {
        var p = BackgroundRecoveryPolicy()
        assert(!p.claimRecovery(at: 0))
        p.start()
        assert(p.isRunning && p.canRecover)
        assert(p.claimRecovery(at: 0))
        assert(!p.claimRecovery(at: 14.9))
        assert(p.claimRecovery(at: 15))
        p.beginInterruption()
        assert(p.state == .interrupted && !p.claimRecovery(at: 30))
        p.endInterruption(shouldResume: false)
        assert(p.state == .deferred && !p.claimRecovery(at: 60))
        p.endInterruption(shouldResume: true) // Duplicate or unpaired end must not override denial.
        assert(p.state == .deferred && !p.claimRecovery(at: 60))
        p.enteredBackground(); p.becameActive()
        assert(!p.claimRecovery(at: 60))
        p.beginInterruption(); p.endInterruption(shouldResume: true)
        assert(p.claimRecovery(at: 60))
        p.becameActive() // Control Center/Siri active transition, no background.
        assert(p.attempts == 1)
        assert(p.claimRecovery(at: 75) && p.claimRecovery(at: 90))
        assert(!p.claimRecovery(at: 105))
        p.enteredBackground(); p.becameActive()
        assert(p.attempts == 0 && !p.claimRecovery(at: 91))
        assert(p.claimRecovery(at: 105))
        p.stop()
        p.endInterruption(shouldResume: true)
        p.enteredBackground(); p.becameActive()
        assert(!p.isRunning && !p.claimRecovery(at: 1000))
        p.start()
        assert(!p.claimRecovery(at: .nan))
        assert(p.claimRecovery(at: 1000))
        p.endInterruption(shouldResume: false) // Unpaired end must not interrupt healthy playback.
        assert(p.canRecover)
        print("Background recovery policy smoke passed")
    }
}
