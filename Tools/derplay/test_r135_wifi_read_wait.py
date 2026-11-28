"""Static checks for slow credential reads; not device execution."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
R=S.split('private func loadWiFiPassword()',1)[1].split('private func refreshNetworkSummary()',1)[0]
class SlowReadTests(unittest.TestCase):
    def test_notice_is_scoped_to_current_read(self):
        notice=R.split('DispatchQueue.main.asyncAfter',1)[1].split('wifiAddSaveQueue.async',1)[0]
        self.assertIn('.now() + 8',notice)
        self.assertIn('self.wifiPasswordReadID == readID',notice)
        self.assertIn('self.statusLabel.text',notice)
        self.assertNotIn('wifiPasswordReadID = nil',notice)
    def test_failure_allows_retry(self):
        self.assertIn('self.passwordLoadedForSSID = nil',R.split('case .failure',1)[1])
