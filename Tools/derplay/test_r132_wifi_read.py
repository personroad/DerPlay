"""Source regressions for asynchronous credential reads; not UIKit device tests."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
R=S.split('private func loadWiFiPassword()',1)[1].split('private func refreshNetworkSummary()',1)[0]
class ReadTests(unittest.TestCase):
    def test_background_read(self):
        bg=R.split('wifiAddSaveQueue.async',1)[1].split('DispatchQueue.main.async',1)[0]
        self.assertIn('WiFiCredentials.password',bg)
        self.assertNotIn('passwordField',bg)
    def test_stale_read(self):
        self.assertLess(R.index('guard self.wifiPasswordReadID == readID'),R.index('self.passwordField.text = saved'))
        self.assertLess(R.index('self.wifiPasswordReadID = nil'),R.index('self.passwordField.text = saved'))
        for method in ('wifiPasswordEdited','networkNameChanged'):
            self.assertIn('wifiPasswordReadID = nil',S.split('func '+method+'()',1)[1].split('    }',1)[0])
    def test_start_guard(self):
        start=S.split('func toggleReceiver()',1)[1].split('if prepareStartupWiFi()',1)[0]
        self.assertIn('!needsNetworkDetails || !wifiPasswordReadPending',start)
    def test_independent_add_can_commit(self):
        add=S.split('private func addWiFiPage()',1)[1].split('private func wifiPresetSections',1)[0]
        self.assertLess(add.index('self.wifiPasswordReadID = nil'),add.index('self.wifiAddSavePending = true'))
        self.assertNotIn('guard !self.wifiAddSavePending, !self.wifiPasswordReadPending',add)
