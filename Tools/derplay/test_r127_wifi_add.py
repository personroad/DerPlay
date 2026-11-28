"""Source guards for isolated Wi-Fi add draft; not UIKit runtime tests."""
import pathlib, unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
class WiFiAddTests(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT/'App/ReceiverViewController.swift').read_text()
        self.add = self.source.split('private func addWiFiPage()',1)[1].split('/// Select, edit or remove',1)[0]
    def test_add_tap_does_not_save_or_reload(self):
        row = self.source.split('rows.append(.page(CWL("添加 Wi-Fi")',1)[1].split('})',1)[0]
        self.assertIn('return self.addWiFiPage()',row)
        self.assertNotIn('saveCurrentWiFiPreset',row)
        before_leave = self.add.split('controller.onLeave =',1)[0]
        self.assertNotIn('saveCurrentWiFiPreset',before_leave)
        self.assertNotIn('reloadVisibleSettings',before_leave)
    def test_independent_controls(self):
        before_leave = self.add.split('controller.onLeave =',1)[0]
        self.assertIn('let name = UITextField(), password = UITextField(), channel = UITextField()',before_leave)
        self.assertIn('let open = UISwitch()',before_leave)
        for field in ('ssidField','passwordField','channelField','openNetworkSwitch','passwordStatus'):
            self.assertNotIn(field,before_leave)
        self.assertIn('password.isSecureTextEntry = true',before_leave)
    def test_commit_only_after_exit_and_restore_on_failure(self):
        leave = self.add.split('controller.onLeave =',1)[1]
        self.assertIn('navigation.viewControllers.contains',leave)
        self.assertIn('controller.onLeave = nil',leave)
        self.assertIn('guard !ssid.isEmpty',leave)
        self.assertLess(leave.index('wifiAddSaveQueue.async'),leave.index('WiFiCredentials.save'))
        self.assertLess(leave.index('case .success(let temporary):'),leave.index('WiFiPresetStore.upsert'))
        self.assertNotIn('saveCurrentWiFiPreset()',leave)
    def test_navigation_guard(self):
        ui = (ROOT/'App/SettingsUI.swift').read_text().split('case .page(let make):',1)[1].split('case .action',1)[0]
        self.assertIn('navigation.topViewController === self',ui)
        self.assertIn('navigation.transitionCoordinator == nil',ui)
        self.assertLess(ui.index('guard'),ui.index('pushViewController'))
