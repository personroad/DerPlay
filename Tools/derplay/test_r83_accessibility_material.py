import unittest
from test_glass_ui import SETTINGS, method

class AccessibilityMaterialTests(unittest.TestCase):
    def test_card_refresh_does_not_rebuild_editing_fields(self):
        self.assertIn('UIAccessibility.isReduceTransparencyEnabled { return .secondarySystemGroupedBackground }', SETTINGS)
        self.assertIn('cell.backgroundColor = settingsCardColor', SETTINGS)
        self.assertIn('selector: #selector(refreshCardMaterial), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification', SETTINGS)
        body = method(SETTINGS, 'refreshCardMaterial')
        self.assertIn('for cell in cells.values', body)
        self.assertNotIn('reload(', body)
        self.assertNotIn('endEditing', body)
    def test_choice_refresh_preserves_selection_and_menu(self):
        self.assertIn('selector: #selector(transparencyChanged), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification', SETTINGS)
        body = method(SETTINGS, 'transparencyChanged')
        self.assertIn('applyMaterial()', body)
        self.assertNotIn('sendActions', body)
        self.assertNotIn('refresh()', body)
        self.assertIn('configuration.title = selectedTitle', method(SETTINGS, 'applyMaterial'))
