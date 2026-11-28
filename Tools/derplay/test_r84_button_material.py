import unittest
from test_glass_ui import GLASS, CONTROLLER, method

class ButtonMaterialRefreshTests(unittest.TestCase):
    def test_home_preserves_current_configuration(self):
        self.assertIn('selector: #selector(refreshHomeButtonMaterials), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification', CONTROLLER)
        body = method(CONTROLLER, 'refreshHomeButtonMaterials')
        for field in ('title', 'image', 'baseBackgroundColor', 'baseForegroundColor', 'contentInsets', 'titleTextAttributesTransformer'):
            self.assertIn(f'replacement.{field} = previous.{field}', body)
        for token in ('addTarget', 'sendActions', 'toggleReceiver(', 'isEnabled =', 'isHidden =', 'Timer('):
            self.assertNotIn(token, body)
        self.assertIn('if let exit = fullscreenExitButton', body)
    def test_navigation_refresh_existing_controls_only(self):
        self.assertIn('selector: #selector(refreshNavigationMaterials), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification', GLASS)
        body = method(GLASS, 'refreshNavigationMaterials')
        self.assertIn('button.accessibilityIdentifier == "derplay.navigation.glass"', body)
        self.assertIn('button.configuration = navigationGlassConfiguration(image: image)', body)
        self.assertNotIn('UIAction', body)
        self.assertNotIn('popViewController', body)
        self.assertIn('button.configuration = nil', GLASS)
        self.assertIn('UIAccessibility.isReduceTransparencyEnabled ? .black', GLASS)
