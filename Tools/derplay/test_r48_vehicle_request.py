import pathlib, unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
class R48Tests(unittest.TestCase):
    def test_local_vehicle_request_is_noop(self):
        s = (ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('receiver.onCarUIRequested = nil', s)
        self.assertNotIn('receiver.onCarUIRequested = {', s)
        self.assertIn('func revealSettings(', s)
    def test_orange_tile_preserved(self):
        s = (ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('("iphone", UIColor(red: 1, green: 149.0 / 255.0, blue: 0, alpha: 1))', s)
        t = (ROOT/'App/SettingsUI.swift').read_text()
        self.assertNotIn('scale *= 0.95', t)
        self.assertIn('fill = resolved', t)
