"""R205 geometry and animation invariants, without the retired floating proxy."""
import unittest
from test_glass_ui import GLASS, CONTROLLER, method
class FloatingCircleTests(unittest.TestCase):
    def test_circle_and_gap(self):
        self.assertIn('width: 44, height: 44', method(GLASS, 'captureGeometry'))
        self.assertIn('slot.width = 44', method(GLASS, 'clearTrailingPlaybackControls'))
        body = method(GLASS, 'render')
        self.assertIn('mix(home.width, end.width)', body)
        self.assertIn('mix(home.height, end.height)', body)
        self.assertIn('playbackTitle.alpha = 1 - p', method(GLASS, 'layoutPlaybackContent'))
    def test_same_rendered_motion(self):
        body = method(GLASS, 'render')
        self.assertIn('height * progress', body)
        self.assertIn('(b-a)*progress', body)
        self.assertIn('self?.render(destination)', method(GLASS, 'setExpanded'))
        self.assertNotIn('CADisplayLink', GLASS)
    def test_weak_target_and_cleanup(self):
        self.assertIn('private weak var homeSlot: UIView?', GLASS)
        self.assertIn('[weak navigation] in navigation?.playbackSlot', method(CONTROLLER, 'prepareConnectionLayer'))
        self.assertIn('connectionControlLayer?.playbackSlot = nil', method(CONTROLLER, 'finishConnectionLayer'))
        self.assertIn('self.animator = nil', method(GLASS, 'setExpanded'))
