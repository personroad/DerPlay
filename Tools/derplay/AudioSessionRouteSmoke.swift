import Foundation
@main struct AudioSessionRouteSmoke {
    static func main() throws {
        typealias P = AudioSessionRoutePolicy
        let a = UUID(), b = UUID()
        let base = P.Snapshot(category: .playback, mixes: false, speakerOverride: false, routeIsCarAudio: false)
        func check(_ owners: Set<P.Owner>, _ mics: [UUID: Bool], _ snapshot: P.Snapshot, _ expected: P.Decision, end: Bool = false) throws {
            let actual = try P.decide(owners: owners, microphoneByStream: mics, snapshot: snapshot, endMedia: end)
            precondition(actual == expected, "\(actual) != \(expected)")
        }
        try check([.pictureInPicture], [:], base, .preserve)
        try check([.keepAlive], [:], base, .configure(category: .playback, mixes: true, defaultToSpeaker: false, overrideSpeaker: false))
        try check([.stream(a), .stream(b), .keepAlive], [a:false,b:true], base, .configure(category: .playAndRecord, mixes: true, defaultToSpeaker: true, overrideSpeaker: false))
        var car = base; car.routeIsCarAudio = true
        try check([.stream(a)], [a:false], car, .configure(category: .playAndRecord, mixes: false, defaultToSpeaker: true, overrideSpeaker: true))
        var sticky = base; sticky.speakerOverride = true; sticky.category = .playAndRecord
        try check([], [:], sticky, .preserve)
        try check([], [:], sticky, .releaseSpeakerAndDeactivate, end: true)
        try check([.keepAlive], [:], sticky, .preserve)
        try check([.keepAlive], [:], sticky, .configure(category: .playback, mixes: true, defaultToSpeaker: false, overrideSpeaker: false), end: true)
        try check([.pictureInPicture], [:], sticky, .preserve)
        try check([], [:], base, .deactivate)
        do { _ = try P.decide(owners: [.stream(a)], microphoneByStream: [:], snapshot: base); preconditionFailure() } catch P.PolicyError.missingStreamRequirements {}
        do { _ = try P.decide(owners: [], microphoneByStream: [a:true], snapshot: base); preconditionFailure() } catch P.PolicyError.unexpectedStreamRequirements {}
        print("AudioSessionRouteSmoke PASS: 12 scenarios")
    }
}
