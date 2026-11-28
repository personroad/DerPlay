import unittest
from pathlib import Path
from test_glass_ui import method
C = (Path(__file__).resolve().parents[2] / 'App/ReceiverViewController.swift').read_text()

class R100TimelineTests(unittest.TestCase):
    def test_diagnostic_only(self):
        body = method(C, 'refreshAirPlayPlaybackStatus')
        snippet = body.split('if let jump = airPlayTimelineTelemetry.sample', 1)[1].split('if let anchor', 1)[0]
        self.assertIn('log("AirPlay local timeline jump:', snippet)
        for forbidden in ('seek(', 'play()', 'requestKeyFrame', 'installAirPlayItem', 'airPlayTimelineStalled ='):
            self.assertNotIn(forbidden, snippet)
    def test_reset_boundaries(self):
        for name in ('resetAirPlayProgress', 'pauseForegroundMaintenance'):
            self.assertIn('airPlayTimelineTelemetry.reset()', method(C, name))
        for name in ('installAirPlayItem', 'stop'):
            self.assertIn('resetAirPlayProgress()', method(C, name))
