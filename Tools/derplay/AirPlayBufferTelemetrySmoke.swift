import Foundation

@main
struct AirPlayBufferTelemetrySmoke {
    static func main() {
        var telemetry = DerPlayAirPlayBufferTelemetry()
        let healthy = DerPlayAirPlayBufferTelemetry.Snapshot(
            isEmpty: false, likelyToKeepUp: true, isFull: false, bufferedAheadSeconds: 2.4
        )
        precondition(telemetry.shouldLog(healthy, at: 100), "The first sample must be logged")
        let fluctuatingDepth = DerPlayAirPlayBufferTelemetry.Snapshot(
            isEmpty: false, likelyToKeepUp: true, isFull: false, bufferedAheadSeconds: 1.8
        )
        precondition(!telemetry.shouldLog(fluctuatingDepth, at: 102), "Buffer depth changes alone must not spam logs")
        let empty = DerPlayAirPlayBufferTelemetry.Snapshot(
            isEmpty: true, likelyToKeepUp: false, isFull: false, bufferedAheadSeconds: 0
        )
        precondition(telemetry.shouldLog(empty, at: 104), "A buffer-state transition must be logged immediately")
        precondition(!telemetry.shouldLog(empty, at: 113.9), "Periodic logging must be throttled")
        precondition(telemetry.shouldLog(empty, at: 114), "A stable state must be sampled every ten seconds")
        precondition(!telemetry.shouldLog(healthy, at: .infinity), "A non-finite clock must be ignored")
        telemetry.reset()
        precondition(telemetry.shouldLog(healthy, at: 115), "Reset must begin a new diagnostic window")
        let bucket = DerPlayAirPlayBufferTelemetry.Snapshot(
            isEmpty: false, likelyToKeepUp: true, isFull: false, bufferedAheadSeconds: 1.26
        ).bufferedAheadBucket
        precondition(bucket == 3, "Buffer depth must be quantized to half-second buckets")
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 12, ranges: [(10, 20)]) == 8)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 12, ranges: [(30, 40), (10, 20)]) == 28)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 25, ranges: [(10, 20), (30, 40)]) == nil)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 9, ranges: [(10, 20)]) == nil)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 20, ranges: [(10, 20)]) == 0)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: .nan, ranges: [(10, 20)]) == nil)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 12, ranges: [(20, 10), (10, .infinity)]) == nil)
        precondition(DerPlayAirPlayLiveEdge.lagSeconds(position: 12, ranges: []) == nil)
        var timeline = DerPlayAirPlayTimelineTelemetry()
        precondition(timeline.sample(position: 10, at: 100, rate: 1) == nil)
        precondition(timeline.sample(position: 12, at: 102, rate: 1) == nil)
        precondition(timeline.sample(position: 11, at: 103, rate: 1) == .backward)
        precondition(timeline.sample(position: 20, at: 104, rate: 1) == nil) // throttled
        precondition(timeline.sample(position: 30, at: 115, rate: 1) == nil) // long gap
        precondition(timeline.sample(position: 40, at: 117, rate: 1) == .forward)
        timeline.reset()
        precondition(timeline.sample(position: 0, at: 118, rate: 1) == nil)
        precondition(timeline.sample(position: .nan, at: 119, rate: 1) == nil)
        precondition(timeline.sample(position: 100, at: 120, rate: 1) == nil)
        precondition(timeline.sample(position: 101, at: 121, rate: 0) == nil)
        precondition(timeline.sample(position: 0, at: 122, rate: 1) == nil)
        print("PASS: AirPlay buffer telemetry and local seekable-edge lag")
    }
}
