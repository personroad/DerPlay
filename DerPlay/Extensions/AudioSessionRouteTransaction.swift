import Foundation

/// Candidate adapter; call only on the shared executor. Checkpoints must
/// represent all writable settings and known activation/override state.
struct AudioSessionRouteTransaction {
    typealias P = AudioSessionRoutePolicy
    struct Backend<Checkpoint> {
        var capture: () throws -> Checkpoint
        var snapshot: () throws -> P.Snapshot
        var configure: (P.Category, Bool, Bool) throws -> Void
        var activate: () throws -> Void
        var speaker: (Bool) throws -> Void
        var deactivate: () throws -> Void
        var restore: (Checkpoint) throws -> Void
    }
    struct Failure: Error {
        let operation: Error
        let rollback: Error?
    }
    enum TransactionError: Error { case activationNotAuthorized, unstableRoute }

    static func apply<C>(owners: Set<P.Owner>, microphones: [UUID: Bool],
                         endMedia: Bool = false, activationAuthorized: Bool,
                         backend b: Backend<C>) throws {
        let initial = try b.snapshot()
        let decision = try P.decide(owners: owners, microphoneByStream: microphones,
                                    snapshot: initial, endMedia: endMedia)
        if !owners.isEmpty && !activationAuthorized { throw TransactionError.activationNotAuthorized }
        if owners.isEmpty && decision == .preserve { return }
        let checkpoint = try b.capture()
        do {
            switch decision {
            case .preserve:
                try b.activate()
                _ = try b.snapshot()
            case .configure(let category, let mixes, let defaultSpeaker, let override):
                if initial.speakerOverride && !override { try b.speaker(false) }
                try b.configure(category, mixes, defaultSpeaker)
                try b.activate()
                let live = try b.snapshot()
                var refreshed = live
                refreshed.speakerOverride = initial.speakerOverride && !endMedia
                let next = try P.decide(owners: owners, microphoneByStream: microphones,
                                        snapshot: refreshed, endMedia: endMedia)
                if case .configure(let c, let m, let d, let s) = next {
                    if c != category || m != mixes || d != defaultSpeaker {
                        try b.configure(c, m, d)
                        try b.activate()
                        var final = try b.snapshot()
                        final.speakerOverride = refreshed.speakerOverride
                        guard try P.decide(owners: owners, microphoneByStream: microphones,
                                           snapshot: final, endMedia: endMedia) == next else {
                            throw TransactionError.unstableRoute
                        }
                    }
                    if s || live.speakerOverride { try b.speaker(s) }
                } else if override { try b.speaker(true) }
            case .releaseSpeakerAndDeactivate:
                try b.speaker(false)
                try b.deactivate()
            case .deactivate:
                try b.deactivate()
            }
        } catch {
            let operation = error
            do { try b.restore(checkpoint) }
            catch { throw Failure(operation: operation, rollback: error) }
            throw Failure(operation: operation, rollback: nil)
        }
    }
}
