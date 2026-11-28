import Foundation

@main
struct AirPlayHLSSmoke {
    static func main() throws {
        let id = UUID()
        let stream = CarPlayHLS(id: id, origin: "http://192.168.1.162:9888")
        let base = "/airplay/\(id.uuidString)/"
        let format = FragmentedMP4.Format(codecString: "avc1.640028", initializationSegment: Data([1, 2]), sampleDuration: 1000, timescale: 30_000, width: 1280, height: 720)
        var arrival: UInt64 = 1_000_000
        func feed(_ count: Int, format: FragmentedMP4.Format) -> Int {
            var ready = 0
            for n in 0..<count {
                if case .ready = stream.append(sample: Data([0, 0, 0, 1, 0x65]), keyframe: n % 30 == 0, format: format, arrivalUs: arrival) { ready += 1 }
                arrival += 33_334
            }
            return ready
        }
        precondition(stream.resource(at: base + "master.m3u8") == nil)
        precondition(feed(91, format: format) == 1)
        let master = String(decoding: stream.resource(at: base + "master.m3u8")!.body, as: UTF8.self)
        precondition(master.contains("RESOLUTION=1280x720"))
        precondition(!master.contains("BANDWIDTH=20000000"))
        let advertised = Int(master.components(separatedBy: "BANDWIDTH=")[1].components(separatedBy: ",")[0])!
        precondition(advertised > 0 && advertised < 1_000_000)
        precondition(master.contains("http://192.168.1.162:9888" + base + "index.m3u8"))
        precondition(stream.resource(at: base + "0.m4s") != nil)
        let initialStats = stream.diagnostics
        precondition(initialStats.retainedSegments >= 3 && initialStats.retainedSegments <= 18)
        precondition(initialStats.retainedBytes > 0 && initialStats.retainedBytes <= 32 * 1024 * 1024)
        precondition(initialStats.pendingBytes >= 0 && initialStats.pendingFrames >= 0)
        precondition(initialStats.playlistAnnounced)
        precondition(stream.resource(at: "/airplay/\(UUID().uuidString)/master.m3u8") == nil)
        let changed = FragmentedMP4.Format(codecString: "avc1.640029", initializationSegment: Data([3, 4]), sampleDuration: 1000, timescale: 30_000)
        precondition(feed(91, format: changed) == 1, "A new format must announce readiness again")
        precondition(!String(decoding: stream.resource(at: base + "master.m3u8")!.body, as: UTF8.self).contains("RESOLUTION="))
        precondition(stream.resource(at: base + "init-0.mp4") == nil)
        precondition(stream.resource(at: base + "init-1.mp4")?.body == Data([3, 4]))
        let playlist = String(decoding: stream.resource(at: base + "index.m3u8")!.body, as: UTF8.self)
        precondition(playlist.contains("#EXT-X-DISCONTINUITY-SEQUENCE:1"))
        precondition(playlist.contains("init-1.mp4"))
        precondition(feed(450, format: changed) == 0)
        precondition(stream.resource(at: base + "0.m4s") == nil)
        let final = String(decoding: stream.resource(at: base + "index.m3u8")!.body, as: UTF8.self)
        precondition(final.components(separatedBy: "#EXTINF:").count - 1 <= 12)
        let finalStats = stream.diagnostics
        precondition(finalStats.retainedSegments <= 18 && finalStats.retainedBytes <= 32 * 1024 * 1024)
        precondition(finalStats.pendingBytes >= 0 && finalStats.pendingFrames >= 0)
        // A recently removed playlist entry must remain fetchable, but not forever.
        let graceID = UUID()
        let grace = CarPlayHLS(id: graceID, origin: "http://127.0.0.1:9888")
        let graceBase = "/airplay/\(graceID.uuidString)/"
        for n in 0...13 {
            _ = grace.append(sample: Data([0x65]), keyframe: true, format: format, arrivalUs: UInt64(n) * 1_000_000)
        }
        let graceList = String(decoding: grace.resource(at: graceBase + "index.m3u8")!.body, as: UTF8.self)
        precondition(graceList.contains("#EXT-X-MEDIA-SEQUENCE:1\n"))
        precondition(grace.resource(at: graceBase + "0.m4s") != nil)
        for n in 14...19 {
            _ = grace.append(sample: Data([0x65]), keyframe: true, format: format, arrivalUs: UInt64(n) * 1_000_000)
        }
        precondition(grace.resource(at: graceBase + "0.m4s") == nil)
        precondition(grace.resource(at: graceBase + "1.m4s") != nil)
        _ = grace.append(sample: Data([0x65]), keyframe: true, format: changed, arrivalUs: 20_000_000)
        precondition(grace.resource(at: graceBase + "1.m4s") == nil)
        // Large segments must obey the existing byte budget even during grace.
        let largeID = UUID()
        let large = CarPlayHLS(id: largeID, origin: "http://127.0.0.1:9888")
        let largeBase = "/airplay/\(largeID.uuidString)/"
        let payload = Data(repeating: 0x65, count: 5 * 1024 * 1024)
        for n in 0...8 {
            _ = large.append(sample: payload, keyframe: true, format: format, arrivalUs: UInt64(n) * 1_000_000)
        }
        precondition(large.resource(at: largeBase + "1.m4s") == nil)
        precondition(large.resource(at: largeBase + "2.m4s") != nil)
        precondition(large.diagnostics.retainedBytes <= 32 * 1024 * 1024)
        let slowID = UUID()
        let slow = CarPlayHLS(id: slowID, origin: "http://127.0.0.1:9888")
        for n in 0...30 {
            _ = slow.append(sample: Data([0, 0, 0, 1, 0x65]), keyframe: n % 10 == 0,
                format: format, arrivalUs: UInt64(n) * 100_000)
        }
        let slowList = String(decoding: slow.resource(at: "/airplay/\(slowID.uuidString)/index.m3u8")!.body, as: UTF8.self)
        let durations = slowList.split(separator: "\n").filter { $0.hasPrefix("#EXTINF:") }.map {
            Double($0.dropFirst(8).dropLast())!
        }
        precondition(durations.count == 3 && durations.reduce(0, +) > 2.9,
            "10 FPS input must represent about three seconds, not one second at configured 30 FPS")
        let frequentID = UUID()
        let frequent = CarPlayHLS(id: frequentID, origin: "http://127.0.0.1:9888")
        var readyAt: Int? = nil
        for n in 0...100 {
            if case .ready = frequent.append(sample: Data([0, 0, 0, 1, 0x65]), keyframe: n % 3 == 0,
                format: format, arrivalUs: UInt64(n) * 33_334) { readyAt = n }
        }
        precondition(readyAt != nil && readyAt! >= 72, "Frequent keyframes must not announce a sub-second live window")
        let frequentList = String(decoding: frequent.resource(at: "/airplay/\(frequentID.uuidString)/index.m3u8")!.body, as: UTF8.self)
        let frequentDurations = frequentList.split(separator: "\n").filter { $0.hasPrefix("#EXTINF:") }.map { Double($0.dropFirst(8).dropLast())! }
        precondition(frequentDurations.allSatisfy { $0 >= 0.799 })
        // A gap belongs to the preceding picture, including across a segment boundary.
        let gapID = UUID()
        let gap = CarPlayHLS(id: gapID, origin: "http://127.0.0.1:9888")
        let sample = Data([0, 0, 0, 1, 0x65])
        _ = gap.append(sample: sample, keyframe: true, format: format, arrivalUs: 1_000_000)
        _ = gap.append(sample: sample, keyframe: true, format: format, arrivalUs: 3_000_000)
        let gapList = String(decoding: gap.resource(at: "/airplay/\(gapID.uuidString)/index.m3u8")!.body, as: UTF8.self)
        precondition(gapList.contains("#EXTINF:2.000,"))
        _ = gap.append(sample: sample, keyframe: true, format: format, arrivalUs: 7_000_000)
        _ = gap.append(sample: sample, keyframe: true, format: format, arrivalUs: 500_000)
        precondition(gap.resource(at: "/airplay/\(gapID.uuidString)/1.m4s") != nil)
        let idleID = UUID()
        let idle = CarPlayHLS(id: idleID, origin: "http://127.0.0.1:9888")
        let idleBase = "/airplay/\(idleID.uuidString)/"
        for n in 0..<3 {
            let t = UInt64(n) * 2_000_000
            _ = idle.append(sample: sample, keyframe: true, format: format, arrivalUs: t)
            precondition(idle.flushIdle(format: format, nowUs: t + 999_999) == .none)
            let event = idle.flushIdle(format: format, nowUs: t + 1_000_000)
            precondition(event == (n == 2 ? .ready : .none))
            precondition(idle.flushIdle(format: format, nowUs: t + 1_500_000) == .none)
        }
        let idleList = String(decoding: idle.resource(at: idleBase + "index.m3u8")!.body, as: UTF8.self)
        precondition(idleList.components(separatedBy: "#EXTINF:1.000,").count == 4)
        _ = idle.append(sample: sample, keyframe: false, format: format, arrivalUs: 6_000_000)
        _ = idle.flushIdle(format: format, nowUs: 7_000_000)
        precondition(idle.resource(at: idleBase + "3.m4s") == nil, "Never publish a non-IDR tail alone")
        print("PASS: HLS readiness, absolute URLs, session scoping, format recovery, rolling eviction and variable-rate timing")
    }
}
