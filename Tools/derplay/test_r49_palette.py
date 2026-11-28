import pathlib, unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
class R49PaletteTests(unittest.TestCase):
    def test_shared_renderer_preserves_color(self):
        s=(ROOT/'App/SettingsUI.swift').read_text()
        self.assertIn('let fill = resolved',s)
        self.assertNotIn('scale *= 0.95',s)
        self.assertIn('withTintColor(.white',s)
        self.assertLess(s.index('if symbol.hasPrefix("DerPlayBrand")'),s.index('let fill = resolved'))
        self.assertLess(s.index('if symbol == "DerPlayVehicleScooter"'),s.index('let fill = resolved'))
    def test_approved_menu_palette(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        for token in ['("gauge.with.dots.needle.67percent", .systemOrange)', '("globe", .systemCyan)', '("rectangle.bottomthird.inset.filled", .systemIndigo)']:
            self.assertIn(token,s)
