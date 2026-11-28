"""R97 guards for diagnostic-only AirPlay buffer and HLS memory telemetry."""
import pathlib
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]

class R97AirPlayTelemetryTests(unittest.TestCase):
    def test_buffer_telemetry_is_throttled_and_diagnostic_only(self):
        policy = (ROOT / 'DerPlay/Extensions/NetworkRecoveryPolicy.swift').read_text()
        for token in ('struct DerPlayAirPlayBufferTelemetry', 'now - $0 >= 10', 'stateChanged', 'mutating func reset()'):
            self.assertIn(token, policy)
        controller = (ROOT / 'App/ReceiverViewController.swift').read_text()
        self.assertIn('item.loadedTimeRanges', controller)
        self.assertIn('item.isPlaybackBufferEmpty', controller)
        self.assertIn('item.isPlaybackLikelyToKeepUp', controller)
        self.assertIn('item.isPlaybackBufferFull', controller)
        self.assertIn('airPlayBufferTelemetry.shouldLog', controller)
        self.assertIn('AirPlay buffer telemetry:', controller)

    def test_buffer_telemetry_resets_for_player_item_and_stop(self):
        controller = (ROOT / 'App/ReceiverViewController.swift').read_text()
        stop = controller.split('private func stop()', 1)[1].split('private func clearStartupHint()', 1)[0]
        start = controller.split('private func startAirPlayTransport()', 1)[1].split('@objc private func airPlayAudioRouteChanged', 1)[0]
        self.assertIn('airPlayBufferTelemetry.reset()', stop)
        self.assertIn('airPlayBufferTelemetry.reset()', start)
        self.assertIn('airPlayBufferTelemetry.reset()', start.split('private func installAirPlayItem', 1)[1])

    def test_hls_retained_byte_accounting_is_incremental_and_bounded(self):
        hls = (ROOT / 'App/FragmentedMP4.swift').read_text()
        self.assertIn('private var retainedBytes = 0', hls)
        self.assertIn('retainedBytes += pending.count', hls)
        self.assertIn('retainedBytes - removed.data.count', hls)
        self.assertNotIn('segments.reduce(0, { $0 + $1.data.count }) > Self.retainedByteLimit', hls)
        self.assertIn('struct Diagnostics: Equatable', hls)
        self.assertIn('pendingBytes: pending.count + (heldSample?.data.count ?? 0)', hls)

    def test_hls_memory_telemetry_is_bounded_and_cleared_on_stop(self):
        server = (ROOT / 'App/VideoOutputServer.swift').read_text()
        self.assertIn('now - $0 >= 10_000_000', server)
        self.assertIn('AirPlay HLS memory:', server)
        stop = server.split('private func stopOnQueue()', 1)[1].split('private func report(', 1)[0]
        self.assertIn('lastHLSDiagnosticsAt = nil', stop)
        self.assertIn('hls = nil', stop)

    def test_ci_runs_airplay_telemetry_and_hls_smokes(self):
        workflow = (ROOT / '.github/workflows/build-ipa.yml').read_text()
        self.assertIn('AirPlayBufferTelemetrySmoke.swift', workflow)
        self.assertIn('Tools/AirPlayHLSSmoke.swift', workflow)

if __name__ == '__main__':
    unittest.main(verbosity=2)
