"""Static checks, not UIKit runtime tests."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
R=S.split('private func loadWiFiPassword()',1)[1].split('private func refreshNetworkSummary()',1)[0]
F=S.split('private func wifiForm()',1)[1].split('private func addWiFiPage()',1)[0]
class DeferredExitTests(unittest.TestCase):
    def test_exit_defers_matching_read(self):
        self.assertLess(F.index('self.activeWiFiForm = nil'),F.index('self.wifiDeferredExitReadID = readID'))
        self.assertLess(F.index('self.wifiDeferredExitReadID = readID'),F.index('self.wifiAddSaveQueue.async'))
    def test_only_successful_current_read_resumes(self):
        self.assertLess(R.index('guard self.wifiPasswordReadID == readID'),R.index('let saveAfterRead'))
        self.assertLess(R.index('self.wifiDeferredExitReadID = nil'),R.index('self.saveCurrentWiFiPreset'))
        self.assertIn('if saveAfterRead, self.activeWiFiForm == nil, !self.running, !self.waitingForNetwork',R)
        self.assertIn('self.saveCurrentWiFiPreset',R.split('if let saved',1)[1].split('case .failure',1)[0])
        self.assertNotIn('saveCurrentWiFiPreset',R.split('case .failure',1)[1])
    def test_new_form_and_edits_cancel_deferred_save(self):
        self.assertIn('wifiDeferredExitReadID = nil',F.split('let controller =',1)[0])
        for name in ('wifiPasswordEdited','networkNameChanged'):
            self.assertIn('wifiDeferredExitReadID = nil',S.split('func '+name+'()',1)[1].split('    }',1)[0])
