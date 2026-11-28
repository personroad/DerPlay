"""R69 source-level menu and shared Dashboard preview checks, not iOS rendering."""
import json, struct, unittest
from test_glass_ui import CONTROLLER, GLASS, SETTINGS, ROOT, method

class R69UI(unittest.TestCase):
    def test_about_identity_and_spacing(self):
        card = method(CONTROLLER, 'aboutIdentityCard')
        self.assertIn('introduction.text = "iPhone 通用无线车机互联工具"', card)
        self.assertIn('[icon, name, introduction, version]', card)
        self.assertIn('version.textAlignment = .center', card)
        self.assertIn('lineHeight + 24', SETTINGS)
        self.assertIn('label.centerYAnchor.constraint(equalTo: container.centerYAnchor)', SETTINGS)
        self.assertIn('AGPL-3.0', method(CONTROLLER, 'aboutPage'))
        self.assertIn('Copyright © 2026 xmz28', method(CONTROLLER, 'aboutPage'))

    def test_dashboard_assets(self):
        assets = ROOT / 'App/Assets.xcassets'
        for suffix in ['Day','Night','Maps','Music','Messages','MapsNight','MusicNight','MessagesNight']:
            folder = assets / ('DerPlayDashboard' + suffix + '.imageset')
            meta = json.loads((folder/'Contents.json').read_text())
            data = (folder/meta['images'][0]['filename']).read_bytes()
            self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
            width, height = struct.unpack('>II', data[16:24])
            self.assertGreater(width, 0)
            self.assertGreater(height, 0)
        self.assertIn('Image(night ? "DerPlayDashboardNight" : "DerPlayDashboardDay")', GLASS)
        self.assertIn('dock == .bottom', GLASS)
        self.assertIn('dock.driverSide(legacy: legacyRight)', GLASS)
        self.assertIn('scaledToFit()', GLASS)

    def test_both_preview_routes_use_same_settings(self):
        for name in ['dockPositionPage']:
            body = method(CONTROLLER, name)
            self.assertIn('DerPlayAppearancePreview(night: night, dock:', body)
            self.assertIn('systemAppearanceIsDark', body)
            self.assertIn('非实际输出', body)
        self.assertIn('title == CWL("Dock 栏")', method(CONTROLLER,'installSystemAppearanceObserver'))
        self.assertIn('!self.running, !self.waitingForNetwork', method(CONTROLLER,'dockPositionPage'))
