import unittest
from test_glass_ui import CONTROLLER, method
class StartupWiFiTests(unittest.TestCase):
    def test_scope_and_single_join(self):
        body=method(CONTROLLER,'prepareStartupWiFi')
        for token in ('!restartingAutomatically','canDetectWiFiName','outputMode.usesInstrumentWiFi','WiFiPresetStore.selected()','guard let current else { finish(true); return }','if current == preset.ssid { finish(true); return }'):
            self.assertIn(token,body)
        self.assertEqual(body.count('NEHotspotConfigurationManager.shared.apply'),1)
        self.assertIn('finish(valid() && matched && self.localCarPlayAddress != nil)',body)
    def test_cancel_and_timeout(self):
        body=method(CONTROLLER,'prepareStartupWiFi')
        self.assertIn('self.startupWiFiTicket == ticket',body)
        self.assertIn('.now() + 35',body)
        self.assertIn('startupWiFiTicket = nil',method(CONTROLLER,'stop'))
        self.assertIn('if startupWiFiTicket != nil { stop() }',method(CONTROLLER,'backgrounded'))
        self.assertIn('if prepareStartupWiFi() { return }',method(CONTROLLER,'toggleReceiver'))
