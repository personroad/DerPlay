"""Source checks for R128; not UIKit or Keychain execution tests."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
A=S.split('private func addWiFiPage()',1)[1].split('/// Select, edit or remove',1)[0]
class R128WiFiSaveTests(unittest.TestCase):
    def test_reservation_precedes_submission(self):
        self.assertLess(A.index('wifiAddSavePending = true'), A.index('wifiAddSaveQueue.async'))
        self.assertLess(A.index('validatedChannel'), A.index('wifiAddSavePending = true'))
    def test_keychain_background_and_ui_main(self):
        bg=A.split('wifiAddSaveQueue.async',1)[1].split('DispatchQueue.main.async',1)[0]
        self.assertIn('WiFiCredentials.save',bg)
        self.assertNotIn('ssidField',bg)
        self.assertNotIn('WiFiPresetStore.upsert',bg)
        self.assertIn('wifiAddSavePending = false',A)
    def test_failure_does_not_replace_fields(self):
        failure=A.split('case .failure(let error):',1)[1].split('self.refreshNetworkSummary()',1)[0]
        self.assertNotIn('ssidField',failure)
        self.assertNotIn('WiFiPresetStore.upsert',failure)
    def test_start_and_join_guard(self):
        for name in ('toggleReceiver','joinConfiguredWiFi','saveCurrentWiFiPreset','forgetWiFiPassword'):
            self.assertIn('!wifiAddSavePending',S.split('func '+name+'(',1)[1].split('    }',1)[0] if name!='toggleReceiver' else S.split('func toggleReceiver(',1)[1].split('if prepareStartupWiFi()',1)[0])
