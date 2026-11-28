"""Static regression checks, not device execution."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
D=S.split('private func deleteWiFiPreset(',1)[1].split('private func saveSettings(',1)[0]
class DeleteTests(unittest.TestCase):
    def test_shared_entry(self):
        self.assertIn('deleteWiFiPreset(ssidField.text ?? "")', S)
        self.assertIn('self.deleteWiFiPreset(preset.ssid)', S)
    def test_background_delete(self):
        self.assertLess(D.index('wifiAddSavePending = true'), D.index('wifiAddSaveQueue.async'))
        bg=D.split('wifiAddSaveQueue.async',1)[1].split('DispatchQueue.main.async',1)[0]
        self.assertIn('WiFiCredentials.forget',bg)
        self.assertNotIn('WiFiPresetStore',bg)
    def test_commit_on_success(self):
        main=D.split('DispatchQueue.main.async',1)[1]
        self.assertLess(main.index('case .success:'), main.index('WiFiPresetStore.remove'))
        self.assertNotIn('WiFiPresetStore.remove',main.split('case .failure:',1)[1])
        self.assertIn('wifiAddSavePending = false',main)
