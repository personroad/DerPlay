import unittest
from test_glass_ui import CONTROLLER, method

class ConnectionGlassTests(unittest.TestCase):
    def test_existing_connection_controls_use_glass_with_legacy_fallback(self):
        self.assertIn('receiverPicker.configuration = DerPlayGlassPalette.nativeButtonConfiguration() ?? .bordered()', CONTROLLER)
        self.assertIn('airPlayRetryButton.configuration = DerPlayGlassPalette.nativeButtonConfiguration() ?? .tinted()', CONTROLLER)
        self.assertIn('receiverPicker.showsMenuAsPrimaryAction = true', CONTROLLER)
        self.assertIn('self?.retryAirPlayTransport()', CONTROLLER)
    def test_refresh_preserves_actions_and_state(self):
        body = method(CONTROLLER, 'refreshConnectionButtonMaterials')
        self.assertIn('receiverPicker.title(for: .normal) ?? receiverPicker.configuration?.title', body)
        self.assertIn('retryConfiguration.title = CWL("重试 AirPlay")', body)
        self.assertIn('refreshConnectionButtonMaterials()', method(CONTROLLER, 'refreshHomeButtonMaterials'))
        for token in ('addAction', 'sendActions', 'retryAirPlayTransport(', '.isEnabled =', '.isHidden =', '.menu =', 'remoteTarget ='):
            self.assertNotIn(token, body)
