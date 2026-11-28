"""R208 morph invariants migrated from proxy to the persistent R210 button."""
import unittest
from test_glass_ui import GLASS, CONTROLLER, method
class R208NavigationMorph(unittest.TestCase):
    def test_navigation_button_only_connection(self):
        body = method(GLASS, 'clearTrailingPlaybackControls')
        self.assertLess(body.index('if reservesConnectionPlayback'), body.index('let anchor = UIView'))
        self.assertIn('page.navigationItem.rightBarButtonItems = [slot] + items', body)
        self.assertIn('navigation.reservesConnectionPlayback = true', method(CONTROLLER, 'prepareConnectionLayer'))
        self.assertNotIn('reservesConnectionPlayback = true', method(CONTROLLER, 'revealSettings'))
    def test_proxy_has_no_action(self):
        layer = GLASS.split('final class ConnectionControlLayer:', 1)[1].split('final class DerPlayPreviewMark:', 1)[0]
        self.assertNotIn('UIButton(', layer)
        self.assertIn('anchor.isUserInteractionEnabled = false', method(GLASS, 'clearTrailingPlaybackControls'))
        self.assertIn('playbackContent.isUserInteractionEnabled = false', layer)
        self.assertEqual(CONTROLLER.count('private let startButton = UIButton'), 1)
    def test_morph_interpolates_to_navigation_target(self):
        self.assertIn('slot.convert(slot.bounds, to: panel)', method(GLASS, 'captureGeometry'))
        body = method(GLASS, 'render')
        for token in ['mix(home.minX, end.minX)', 'mix(home.width, end.width)', 'layoutPlaybackContent(progress)']:
            self.assertIn(token, body)
    def test_no_extra_backdrop(self):
        self.assertNotIn('settingsBackdropView', CONTROLLER)
        self.assertIn('modalPresentationStyle = .pageSheet', method(CONTROLLER, 'revealSettings'))
