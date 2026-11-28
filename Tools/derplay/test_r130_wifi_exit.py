"""Static regression checks for ordinary Wi-Fi form exit, not UIKit execution."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
F=S.split('private func wifiForm()',1)[1].split('private func addWiFiPage()',1)[0]
class WiFiExitTests(unittest.TestCase):
    def test_validate_before_reserve(self):
        self.assertLess(F.index('guard ssid.utf8.count'), F.index('self.wifiAddSavePending = true'))
        self.assertLess(F.index('self.wifiAddSavePending = true'), F.index('self.wifiAddSaveQueue.async'))
    def test_no_sync_commit_on_exit(self):
        self.assertNotIn('saveCurrentWiFiPreset()', F)
        bg=F.split('self.wifiAddSaveQueue.async',1)[1].split('DispatchQueue.main.async',1)[0]
        self.assertIn('WiFiCredentials.save',bg)
        self.assertNotIn('ssidField',bg)
        self.assertNotIn('WiFiPresetStore.upsert',bg)
    def test_commit_only_on_success(self):
        main=F.split('self.wifiAddSaveQueue.async',1)[1].split('DispatchQueue.main.async',1)[1]
        self.assertLess(main.index('self.wifiAddSavePending = false'),main.index('case .success'))
        self.assertLess(main.index('case .success'),main.index('WiFiPresetStore.upsert'))
        failure=main.split('case .failure(let error):',1)[1].split('self.refreshNetworkSummary()',1)[0]
        self.assertNotIn('WiFiPresetStore.upsert',failure)
        self.assertNotIn('ssidField',failure)
