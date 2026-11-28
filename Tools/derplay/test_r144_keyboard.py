"""Keyboard accessory removal: static source guards, not device UI tests."""
import unittest
from test_glass_ui import CONTROLLER, SETTINGS, method
class KeyboardTests(unittest.TestCase):
    def test_no_custom_done_accessories(self):
        self.assertNotIn('inputAccessoryView', CONTROLLER)
        self.assertNotIn('UIToolbar()', CONTROLLER)
    def test_system_return_and_editing_callbacks_preserved(self):
        for name in ('configureSettingsControls', 'addWiFiPage'):
            body=method(CONTROLLER,name)
            self.assertIn('returnKeyType = .done',body)
            self.assertIn('for: .editingDidEndOnExit',body)
        self.assertIn('for: .editingDidEnd)',method(CONTROLLER,'configureSettingsControls'))
    def test_numeric_keyboard_can_dismiss_by_scroll_or_navigation(self):
        self.assertIn('keyboardDismissMode = .interactive',SETTINGS)
        self.assertIn('view.endEditing(true)',method(SETTINGS,'viewWillDisappear'))
