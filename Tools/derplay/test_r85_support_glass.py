import pathlib
import unittest

SOURCE = (pathlib.Path(__file__).resolve().parents[2] / 'App/SupportViews.swift').read_text()

class SupportGlassTests(unittest.TestCase):
    def test_material_refresh_preserves_action(self):
        helper = SOURCE.split('private final class SupportGlassActionButton:', 1)[1].split('enum DeveloperSupport', 1)[0]
        self.assertEqual(helper.count('addAction(action, for: .primaryActionTriggered)'), 1)
        refresh = helper.split('@objc private func refreshMaterial()', 1)[1]
        self.assertIn('nativeButtonConfiguration()', refresh)
        self.assertIn('configuration = legacyConfiguration', refresh)
        self.assertIn('reduceTransparencyStatusDidChangeNotification', helper)
        self.assertNotIn('addAction', refresh)
        for prop in ('title', 'image', 'imagePadding', 'cornerStyle', 'baseForegroundColor', 'baseBackgroundColor', 'titleTextAttributesTransformer'):
            self.assertIn(f'glass.{prop} = legacyConfiguration.{prop}', refresh)

    def test_existing_support_buttons_and_actions(self):
        for name in ('sendConfig', 'copyConfig', 'configuration'):
            self.assertIn(f'SupportGlassActionButton(legacy: {name}, action: UIAction', SOURCE)
        self.assertIn('DeveloperSupport.composeEmail(from: self)', SOURCE)
        self.assertIn('UIPasteboard.general.string = DeveloperSupport.email', SOURCE)
        self.assertIn('if wechat { self?.saveQRCode() } else { self?.openAlipay() }', SOURCE)
