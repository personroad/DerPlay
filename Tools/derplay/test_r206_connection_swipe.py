import unittest
from test_glass_ui import GLASS, CONTROLLER, method
class ConnectionSwipeTests(unittest.TestCase):
    def test_only_connection_stack_has_control(self):
        self.assertIn('navigation.reservesConnectionPlayback = true', method(CONTROLLER,'prepareConnectionLayer'))
        self.assertNotIn('reservesConnectionPlayback = true', method(CONTROLLER,'revealSettings'))
        self.assertNotIn('startButton.isHidden = true', method(CONTROLLER,'revealSettings'))
        self.assertIn('let limit = maximum * 0.86',method(GLASS,'resolvedHeight'))
    def test_up_pan_cancels_touch_and_preserves_tap(self):
        for token in ['gesture.cancelsTouchesInView = true','button.addGestureRecognizer(buttonPan)']:
            self.assertIn(token,GLASS)
        self.assertIn('action: #selector(connectionPlaybackTapped)',CONTROLLER)
        self.assertIn('velocity.y < 0',method(GLASS.split('final class ConnectionControlLayer:',1)[1],'gestureRecognizerShouldBegin'))
    def test_pan_opens_connection_not_playback(self):
        self.assertIn('settingsNavigation == nil, presentedViewController == nil',method(CONTROLLER,'prepareConnectionLayer'))
        self.assertIn('onBeginOpening?() != true',method(GLASS,'drag'))
        self.assertNotIn('toggleReceiver',method(GLASS,'drag'))
