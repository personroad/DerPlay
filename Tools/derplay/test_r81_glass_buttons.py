import unittest
from test_glass_ui import GLASS, CONTROLLER, method

class NativeButtonTests(unittest.TestCase):
    def test_native_and_fallback(self):
        self.assertIn('return prominent ? .prominentGlass() : .glass()', GLASS)
        self.assertIn('!UIAccessibility.isReduceTransparencyEnabled', GLASS)
        self.assertIn('native ?? UIButton.Configuration.filled()', GLASS)
        self.assertIn('nativeButtonConfiguration(prominent: true) ?? .filled()', CONTROLLER)
    def test_existing_targets_and_size(self):
        self.assertIn('applyVideoButtonGlass(fullscreenButton', CONTROLLER)
        self.assertIn('applyVideoButtonGlass(exit, image: icon)', CONTROLLER)
        self.assertIn('#selector(showFullscreen)', CONTROLLER)
        self.assertIn('#selector(hideFullscreen)', method(CONTROLLER,'addFullscreenExitButton'))
        self.assertIn('playbackHomeSlot.heightAnchor.constraint(equalToConstant: 80)', CONTROLLER)
        self.assertIn('startButton.tintColor = active ? DerPlayGlassPalette.stopRed : DerPlayGlassPalette.startGreen', CONTROLLER)
