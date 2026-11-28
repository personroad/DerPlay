"""Source integration guards; not live protocol tests."""
import unittest
from test_glass_ui import CONTROLLER, method

class ProtocolGeometryTests(unittest.TestCase):
    def test_resolution_label_waits_only_for_negotiating_outputs(self):
        body = method(CONTROLLER, 'actualOutputResolutionLabel')
        self.assertIn('outputMode == .browser && videoOutputSwitch.isOn && !browserGeometryResolvedForSession', body)
        self.assertIn('outputMode == .carLife && liveDisplay == nil', body)
        self.assertIn('followsCarScreen && modeControl.selectedSegmentIndex == 1', body)
    def test_carlife_fixed_axis_cap_and_instrument_bypass(self):
        body = method(CONTROLLER, 'planDisplay')
        self.assertIn('absoluteBounds: outputMode == .carLife ? .init(width: 1920, height: 1080) : nil', body)
        for token in ['if let cfmoto = cfmotoProfile', 'if let profile = outputMode.zeehoProfile', 'if let mode = outputMode.ninebotMode', 'if outputMode == .tailing']:
            self.assertLess(body.index(token), body.index('DisplayGeometry.fitPreservingRatio'))
        self.assertIn('if outputMode != .browser { fps = min(fps, 30) }', body)
        self.assertIn('if outputMode != .browser { codec = .h264 }', body)
    def test_planned_protocols_stay_disabled(self):
        body = method(CONTROLLER, 'interconnectRows')
        self.assertIn('"尚未开放"', body)
        for token in ['derplay.iccoa.direct', 'derplay.easyconnection']:
            self.assertIn('plannedRow("'+token+'"', body)
