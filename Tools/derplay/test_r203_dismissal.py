"""R203 dismissal invariants migrated to R210's persistent, single-button layer."""
import unittest
from test_glass_ui import GLASS, CONTROLLER, method
class DismissalLandingTests(unittest.TestCase):
    def test_detach_before_animating_to_home(self):
        # No proxy to detach: interpolate the real button back to its home slot.
        body = method(GLASS, 'render')
        for token in ['mix(home.minY, end.minY)', 'button.frame = CGRect', 'layoutPlaybackContent(progress)']:
            self.assertIn(token, body)
        close = method(GLASS, 'setExpanded')
        self.assertLess(close.index('self.render(destination)'), close.index('self.onClosed?()'))
    def test_home_target_is_actual_button(self):
        body = method(GLASS, 'captureGeometry')
        self.assertIn('homeSlot.window === window', body)
        self.assertIn('homeSlot.convert(homeSlot.bounds, to: self)', body)
        self.assertIn('ConnectionControlLayer(button: startButton, homeSlot: playbackHomeSlot)', CONTROLLER)
    def test_cancel_and_cleanup(self):
        interrupt = method(GLASS, 'interrupt')
        for token in ['panel.layer.presentation()', 'animator.stopAnimation(true)', 'render(current)']:
            self.assertIn(token, interrupt)
        self.assertIn(': dragReturnOpen', method(GLASS, 'drag'))
        close = method(CONTROLLER, 'finishConnectionLayer')
        for token in ['(navigation as? DerPlayGlassNavigationController)?.onPlaybackSlotChanged = nil', 'uninstallContent(navigation.view)', 'navigation.removeFromParent()']:
            self.assertIn(token, close)
