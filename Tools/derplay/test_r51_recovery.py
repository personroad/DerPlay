import unittest
from test_glass_ui import CONTROLLER, method, ROOT
class InstrumentRecoveryTests(unittest.TestCase):
    def test_scope_and_no_live_restart(self):
        start=method(CONTROLLER,'toggleReceiver')
        self.assertIn('if outputMode.usesInstrumentWiFi {\n                    watchInstrumentStartupRecovery',start)
        body=method(CONTROLLER,'watchInstrumentStartupRecovery')
        for token in ('!self.displayedVideo','self.localStartupID == startupID','NEHotspotNetwork.fetchCurrent','self.instrumentRecoveryProbe.complete(ticket','self.instrumentRecoveryProbe.cancel(ticket)','self.instrumentRecoveryResult == .eligible','self.localCarPlayAddress == address','self.networkRestartCount < 2','epoch == self.instrumentRecoveryEpoch','systemUptime < deadline'):
            self.assertIn(token,body)
        self.assertLess(body.index('policy.sample(address: address, active: true) == .retry'),body.index('self.stop()'))
    def test_cancel_and_project_membership(self):
        self.assertIn('instrumentRecoveryProbe.stop()',method(CONTROLLER,'stop'))
        self.assertIn('instrumentRecoveryProbe.setForeground(false)',method(CONTROLLER,'willResignActive'))
        for name in ('NetworkRecoveryPolicy','NetworkIdentityGate','NetworkSessionProbe'):
            for path in ('Tools/generate_project.py','TDSCarKit.xcodeproj/project.pbxproj'):
                self.assertIn(name+'.swift',(ROOT/path).read_text())
