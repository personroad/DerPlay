import pathlib
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]

class R98AirPlayLiveEdgeTests(unittest.TestCase):
    def test_measurement_only_inside_existing_log_gate(self):
        source = (ROOT / 'App/ReceiverViewController.swift').read_text()
        refresh = source.split('private func refreshAirPlayPlaybackStatus()', 1)[1]
        gate = refresh.split('if airPlayBufferTelemetry.shouldLog(bufferSnapshot, at: now) {', 1)[1].split('if player.timeControlStatus == .waitingToPlayAtSpecifiedRate', 1)[0]
        self.assertIn('item.seekableTimeRanges', gate)
        self.assertIn('localSeekableEdgeLag=', gate)
        self.assertNotIn('seek(to:', gate)
        self.assertEqual(source.count('DerPlayAirPlayLiveEdge.lagSeconds'), 1)

    def test_existing_buffer_and_policy_preserved(self):
        source = (ROOT / 'App/ReceiverViewController.swift').read_text()
        self.assertIn('preferredForwardBufferDuration = 3', source)
        self.assertIn('guard player.isExternalPlaybackActive else', source)
