"""R133 static checks; not device execution tests."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
SAVE=S.split('private func saveCurrentWiFiPreset(',1)[1].split('@objc private func displaySettingChanged',1)[0]
SWITCH=S.split('private func wifiPresetSections(',1)[1].split('// MARK: 输出方式',1)[0]
class R133WiFiSwitchTests(unittest.TestCase):
    def test_background_write(self):
        self.assertLess(SAVE.index('wifiAddSavePending = true'), SAVE.index('wifiAddSaveQueue.async'))
        bg=SAVE.split('wifiAddSaveQueue.async',1)[1].split('DispatchQueue.main.async',1)[0]
        self.assertIn('WiFiCredentials.save',bg)
        self.assertNotIn('WiFiPresetStore.upsert',bg)
        self.assertNotIn('Field',bg)
    def test_metadata_only_after_success(self):
        success,failure=SAVE.split('case .success(let temporary):',1)[1].split('case .failure(let error):',1)
        self.assertIn('WiFiPresetStore.upsert',success)
        self.assertIn('completion(true)',success)
        self.assertNotIn('WiFiPresetStore.upsert',failure)
        self.assertIn('completion(false)',failure)
    def test_switch_waits_for_save(self):
        body=SWITCH.split('self.saveCurrentWiFiPreset {',1)[1].split('self.reloadVisibleSettings()',1)[0]
        self.assertLess(body.index('guard saved'),body.index('self.applyWiFiPreset(preset)'))
        self.assertIn('!self.running, !self.waitingForNetwork',body)
