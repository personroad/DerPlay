import unittest
from test_glass_ui import CONTROLLER, GLASS, method
class StartupNavigationTests(unittest.TestCase):
    def test_single_button_uses_start_stop(self):
        self.assertIn('startButton.addTarget(self, action: #selector(connectionPlaybackTapped)', CONTROLLER)
        body = method(CONTROLLER, 'connectionPlaybackTapped')
        self.assertIn('toggleReceiver()', body)
        self.assertIn('acceptsPlaybackTap == true', body)
        self.assertIn('revealSettings(certificate: true)', body)
    def test_validation_does_not_open_settings(self):
        body=method(CONTROLLER,'toggleReceiver')
        self.assertNotIn('revealSettings(',body)
        self.assertIn('reportStartupValidation(CWL("请输入 Wi-Fi 密码；开放网络请选择“无密码”。")); return',body)
        self.assertIn('guard !needsNetworkDetails || openNetworkSwitch.isOn || !(passwordField.text ?? "").isEmpty else',body)
        self.assertIn('try config.validate()',body)
        self.assertIn('if running || waitingForNetwork { stop(); return }',body)
    def test_error_uses_current_presenter(self):
        body=method(CONTROLLER,'reportStartupValidation')
        self.assertIn('statusLabel.text = message',body)
        self.assertIn('settingsNavigation ?? self',body)
        self.assertIn('presenter.presentedViewController == nil',body)
        self.assertIn('alert(CWL("启动"), message)',body)
        self.assertNotIn('revealSettings',body)
