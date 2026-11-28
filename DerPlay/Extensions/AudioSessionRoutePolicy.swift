import Foundation

/// Candidate only: no AVFoundation calls. Inputs must be collected on the
/// shared audio executor; the adapter must not infer microphone needs from UUIDs.
struct AudioSessionRoutePolicy {
    typealias Owner = AudioSessionOwnershipPolicy.Owner
    enum Category: Equatable { case playback, playAndRecord, other }
    struct Snapshot: Equatable {
        var category: Category
        var mixes: Bool
        var speakerOverride: Bool
        var routeIsCarAudio: Bool
    }
    enum Decision: Equatable {
        case preserve
        case configure(category: Category, mixes: Bool, defaultToSpeaker: Bool, overrideSpeaker: Bool)
        case releaseSpeakerAndDeactivate
        case deactivate
    }
    enum PolicyError: Error { case missingStreamRequirements, unexpectedStreamRequirements }

    /// Explicit end-of-media is the only event allowed to remove sticky speaker
    /// routing. A temporary stream replacement is not an end-of-media event.
    static func decide(owners: Set<Owner>, microphoneByStream: [UUID: Bool],
                       snapshot: Snapshot, endMedia: Bool = false) throws -> Decision {
        let streams = Set(owners.compactMap { owner -> UUID? in
            if case .stream(let id) = owner { return id }; return nil
        })
        guard streams.isSubset(of: Set(microphoneByStream.keys)) else { throw PolicyError.missingStreamRequirements }
        guard Set(microphoneByStream.keys).isSubset(of: streams) else { throw PolicyError.unexpectedStreamRequirements }
        let stickySpeaker = snapshot.speakerOverride && !endMedia
        if owners.isEmpty {
            if stickySpeaker { return .preserve }
            return snapshot.speakerOverride ? .releaseSpeakerAndDeactivate : .deactivate
        }
        let keepAlive = owners.contains(.keepAlive)
        if streams.isEmpty && !endMedia {
            // PiP alone does not change a compatible existing audio category.
            if snapshot.category == .playAndRecord { return .preserve }
            if snapshot.category == .playback && (!keepAlive || snapshot.mixes) { return .preserve }
        }
        let speaker = stickySpeaker || (!streams.isEmpty && snapshot.routeIsCarAudio)
        let duplex = speaker || microphoneByStream.values.contains(true)
        let mixes = keepAlive || (streams.isEmpty && (snapshot.mixes || snapshot.category == .other))
        return .configure(category: duplex ? .playAndRecord : .playback,
                          mixes: mixes, defaultToSpeaker: duplex, overrideSpeaker: speaker)
    }
}
