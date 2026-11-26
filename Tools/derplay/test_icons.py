#!/usr/bin/env python3
"""Protect approved AppIcon assets and their appearance mapping; not a device test."""
import hashlib
import json
from pathlib import Path
import struct
import unittest

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'App/Assets.xcassets/AppIcon.appiconset'

class IconTests(unittest.TestCase):
    def test_vehicle_default_assets_and_selection(self):
        assets = ASSETS.parent
        contents = []
        for name in ('DerPlayVehicleDay', 'DerPlayVehicleNight'):
            folder = assets / (name + '.imageset')
            entries = json.loads((folder / 'Contents.json').read_text())['images']
            self.assertEqual(entries, [{'filename': 'icon.png', 'idiom': 'universal'}])
            data = (folder / 'icon.png').read_bytes()
            self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
            self.assertEqual(struct.unpack('>IIBB', data[16:26]), (120, 120, 8, 2))
            contents.append(data)
        self.assertNotEqual(*contents)
        source = (ROOT / 'App/ReceiverViewController.swift').read_text()
        self.assertIn('night ? "DerPlayVehicleNight" : "DerPlayVehicleDay"', source)
        self.assertIn('choice == .system && systemAppearanceIsDark', source)
        self.assertIn('config.oemIconPNG = customVehicleIcon ?? defaultVehicleIcon()', source)
        self.assertIn('self.customVehicleIcon ?? self.defaultVehicleIcon(appearanceIndex: savedLayout?.appearance)', source)
        self.assertIn('if let data = customVehicleIcon ?? defaultVehicleIcon()', source)

    def test_interconnect_brand_assets(self):
        expected = {'CarLife': '5e4a76562da486b09e770c5095908f6b6ba722c2d215d5f5685d2e02715e42eb', 'Ninebot': 'f5dd84bd37286f9fdbf585f2ceb47f7534a5fcebbfdf3204bdcf9c45593d976a', 'Tailing': '12503b6d9d4abc0d1af672c2ec40087ce1a90d2085c6361da267c54556906107', 'Zeeho': 'a1ea8b3be1dbdc9fc2032535698241a6e09384afb7df1c4c4f59b9efded1e410', 'Cfmoto': 'a4bf80c4417116dd05e9340a1815ddb346e1e42990529ad835d7edf85b5e9df0'}
        source = (ROOT / 'App/ReceiverViewController.swift').read_text()
        renderer = (ROOT / 'App/SettingsUI.swift').read_text()
        for name, digest in expected.items():
            asset = 'DerPlayBrand' + name
            folder = ASSETS.parent / (asset + '.imageset')
            self.assertEqual(json.loads((folder / 'Contents.json').read_text())['images'], [{'filename': 'logo.png', 'idiom': 'universal'}])
            self.assertEqual(hashlib.sha256((folder / 'logo.png').read_bytes()).hexdigest(), digest)
            self.assertIn(asset, source)
        self.assertIn('UIImage(named: symbol)', renderer)
        self.assertIn('shape.addClip()', renderer)
        self.assertIn('withRenderingMode(.alwaysOriginal)', renderer)

    def test_planned_protocol_brand_assets(self):
        source = (ROOT / 'App/ReceiverViewController.swift').read_text()
        bridge = (ROOT / 'App/DerPlayUpstreamBridge.swift').read_text()
        renderer = (ROOT / 'App/SettingsUI.swift').read_text()
        self.assertIn('identifier: UIAction.Identifier(rawValue: descriptor.id)', bridge)
        self.assertIn('attributes: .disabled', bridge)
        self.assertIn('"尚未开放", icon: (icon, .systemBlue)', source)
        folder = ASSETS.parent / 'DerPlayBrandEasyConnection.imageset'
        self.assertEqual(json.loads((folder / 'Contents.json').read_text())['images'], [{'filename': 'logo.png', 'idiom': 'universal'}])
        self.assertEqual(hashlib.sha256((folder / 'logo.png').read_bytes()).hexdigest(), '1f6f1c22b03460a413e85edd9452f5719664989fba0721fbc4cfbed6de0790dc')
        self.assertIn('plannedRow("derplay.easyconnection", icon: "DerPlayBrandEasyConnection")', source)
        self.assertIn('"DerPlayBrandEasyConnection"', renderer)
        folder = ASSETS.parent / 'DerPlayBrandCarlink.imageset'
        self.assertEqual(json.loads((folder / 'Contents.json').read_text())['images'], [{'filename': 'logo.png', 'idiom': 'universal'}])
        self.assertEqual(hashlib.sha256((folder / 'logo.png').read_bytes()).hexdigest(), '3521b23dbe6fad10e45d34a4a1eaf4c817ca75967a9482c4c45b5ddf2c4e7f47')
        self.assertIn('plannedRow("derplay.iccoa.direct", icon: "DerPlayBrandCarlink")', source)
        self.assertIn('"DerPlayBrandCarlink"', renderer)

    def test_settings_icon_renderers_use_trait_display_scale(self):
        renderer = (ROOT / 'App/SettingsUI.swift').read_text()
        body = renderer.split('enum SettingsIcon {', 1)[1].split('struct SettingsRow', 1)[0]
        self.assertEqual(body.count('format.scale = max(1, traits.displayScale)'), 2)
        self.assertEqual(body.count('UIGraphicsImageRenderer(size: size, format: format)'), 2)
        self.assertNotIn('UIGraphicsImageRenderer(size: size).image', body)

    def test_appearance_mapping(self):
        images = json.loads((ASSETS / 'Contents.json').read_text())['images']
        default = [x for x in images if not x.get('appearances')]
        dark = [x for x in images if {'appearance': 'luminosity', 'value': 'dark'} in x.get('appearances', [])]
        for entries, filename in [(default, 'AppIcon.png'), (dark, 'AppIcon-dark.png')]:
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]['filename'], filename)
            self.assertEqual(entries[0]['size'], '1024x1024')
            self.assertEqual(entries[0]['idiom'], 'universal')
            self.assertEqual(entries[0]['platform'], 'ios')

    def test_approved_rgb_png_assets(self):
        lock = json.loads((ROOT / 'DerPlay/icon-lock.json').read_text())
        self.assertEqual(set(lock), {'AppIcon.png', 'AppIcon-dark.png'})
        for name, digest in lock.items():
            data = (ASSETS / name).read_bytes()
            self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
            self.assertEqual(data[12:16], b'IHDR')
            self.assertEqual(struct.unpack('>IIBB', data[16:26]), (1024, 1024, 8, 2))
            self.assertEqual(hashlib.sha256(data).hexdigest(), digest)
        self.assertNotEqual(*lock.values())

if __name__ == '__main__':
    unittest.main(verbosity=2)
