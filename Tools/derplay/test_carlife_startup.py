"""Source integration guards; not a device or network handshake test."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[2]
class CarLifeStartupTests(unittest.TestCase):
    def setUp(self):
        self.ui = (ROOT/'App/ReceiverViewController.swift').read_text()
        self.native = (ROOT/'App/NativeReceiver.swift').read_text()
        self.output = (ROOT/'App/CarLifeOutput.swift').read_text()
    def test_first_reply_uses_selected_raster(self):
        setup = self.output.split('case 98311:',1)[1].split('case 98313:',1)[0]
        self.assertLess(setup.index('selectDisplay(Int(rawWidth)'),setup.index('send(encoderChannel, 65544'))
        self.assertLess(setup.index('send(encoderChannel, 65544'),setup.index('onDisplayNegotiated?(width, height, fps)'))
        self.assertIn('(selectDisplay == nil || displayNegotiated)', self.output)
        self.assertIn('negotiation.commit(width: width, height: height)', self.output)
    def test_repeat_encoder_request_preserves_renderer_fps(self):
        setup = self.output.split('case 98311:',1)[1].split('case 98313:',1)[0]
        self.assertIn('if displayNegotiated {',setup)
        self.assertIn('} else { fps = proposedFPS }',setup)
        self.assertIn('number(3, Int64(fps))',setup)
    def test_prepare_preserves_sockets_and_only_then_starts_rendering(self):
        branch = self.ui.split('if config.carLifeEnabled && followsCarScreen {',1)[1].split('\n            } else {',1)[0]
        self.assertLess(branch.index('receiver.prepareCarLife'),branch.index('self.startPreparedCarLife'))
        self.assertIn('negotiated.width = width; negotiated.height = height',branch)
        self.assertNotIn('receiver.start(configuration:',branch)
        self.assertNotIn('watchStartupAddress',branch)
        self.assertIn('preservePreparedCarLife: true',self.ui)
        self.assertIn('if !preserveCarLife { carLife.stop() }',self.native)
        self.assertIn('configuration.carLifeEnabled && !preservePreparedCarLife',self.native)
    def test_cancel_and_timeout_never_start_fallback(self):
        self.assertIn('carLifeNegotiationTimeout?.cancel(); carLifeNegotiationTimeout = nil',self.ui)
        self.assertIn('self.localStartupID == startupID,\n                          self.outputMode == .carLife, self.carLifeNegotiationTimeout != nil',self.ui)
        self.assertIn('self.stop()\n                    self.statusLabel.text = "未完成 CarLife 分辨率协商',self.ui)
        for obsolete in ('adaptCarLifeScreen','carLifeRestartToken','carLifeAdaptations','carLifeReportedSize','onCarLifeDisplaySize'):
            self.assertNotIn(obsolete, self.ui+self.native)
        self.assertIn('guard running, outputMode != .carLife, reportedScreen != nil', self.ui)
    def test_direction_is_carlife_only_and_persisted(self):
        self.assertNotIn('carLifeDirectionControl', self.ui)
        self.assertIn('UserDefaults.standard.integer(forKey: "derPlayCarLifeDirection")', self.ui)
        self.assertIn('evidence.report(raw: raw)', self.output)
        self.assertIn('area: area, direction: carLifeDirection', self.ui)
        self.assertIn('autoDisplayArea: area, direction: direction', self.native)
        self.assertIn('Negotiation(area: $0, direction: direction)', self.output)
        self.assertIn('session.displayDirection = displayNegotiation.direction', self.output)
        self.assertIn('direction: negotiation.direction', self.output)
        self.assertIn('direction: displayDirection', self.output)
if __name__ == '__main__': unittest.main(verbosity=2)
