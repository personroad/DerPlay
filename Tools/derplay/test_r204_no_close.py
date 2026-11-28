import unittest
from test_glass_ui import GLASS, CONTROLLER, method
class NoCloseButtonTests(unittest.TestCase):
    def test_no_close_or_playback_item(self):
        body=method(GLASS,'clearTrailingPlaybackControls')
        self.assertIn('!= "derplay.navigation.playback"',body)
        self.assertIn('!= "derplay.close.settings"',body)
        self.assertNotIn('glassButton(',body)
        self.assertIn('clearTrailingPlaybackControls(on: topViewController)',GLASS)
        self.assertIn('clearTrailingPlaybackControls(on: viewController)',GLASS)
    def test_drag_dismissal_and_back_remain(self):
        self.assertIn('sheet.prefersGrabberVisible = true',method(CONTROLLER,'revealSettings'))
        self.assertIn('presentationControllerDidDismiss',CONTROLLER)
        self.assertIn('chevron.backward',method(GLASS,'installBack'))
        self.assertIn('setExpanded(false)',method(GLASS,'closeFromBackdrop'))
        self.assertIn('setExpanded(open)',method(GLASS,'drag'))
