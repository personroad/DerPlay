import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER,method
class CertificateRouteTests(unittest.TestCase):
    def test_missing_identity_routes_before_start(self):
        body=method(CONTROLLER,'connectionPlaybackTapped')
        self.assertIn('!running && !waitingForNetwork && carLifeNegotiationTimeout == nil && identity == nil',body)
        self.assertLess(body.index('guard !derPlayIdentityImporting'),body.index('identity == nil'))
        self.assertLess(body.index('revealSettings(certificate: true)'),body.index('toggleReceiver()'))
        self.assertIn('return\n        }\n        toggleReceiver()',body)
    def test_connection_closes_before_certificate_sheet(self):
        body=method(CONTROLLER,'finishConnectionLayer')
        self.assertLess(body.index('settingsDismissed()'),body.index('revealSettings(certificate: true)'))
        self.assertIn('opensCertificateAfterConnectionClose = false',body)
        self.assertIn('!self.opensCertificateAfterConnectionClose',CONTROLLER)
    def test_color_enabled_without_identity_but_not_during_import(self):
        self.assertIn('startButton.isEnabled = active || !derPlayIdentityImporting',method(CONTROLLER,'refreshDerPlayPanel'))
        self.assertIn('startButton.isEnabled = !derPlayIdentityImporting',method(CONTROLLER,'loadIdentity'))
        self.assertIn('startButton.isEnabled = !derPlayIdentityImporting',method(CONTROLLER,'modeChanged'))
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R212-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R213-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        for key,expected in [('files',{'App/ReceiverViewController.swift'}),('methods',{'loadIdentity'})]:
            self.assertEqual(set(old[key]),set(lock[key]))
            self.assertEqual({n for n in old[key] if old[key][n]!=lock[key][n]},expected)
