"""R142 source guards for General / Night Mode labels and iOS 26 navigation transitions."""
import json
import unittest
from test_glass_ui import CONTROLLER, GLASS, ROOT, method

class R142GeneralNightModeNavigationTests(unittest.TestCase):
    def test_general_label_is_consistent_on_dashboard_and_settings_title(self):
        self.assertIn('menuRow(CWL("通用设置"), symbol: "gearshape", action: settings)', GLASS)
        root = method(CONTROLLER, "rootSettingsPage")
        self.assertIn('page(CWL("通用设置"))', root)
        self.assertNotIn('软件设置', root)
        self.assertIn('"通用设置"', (ROOT / "App/Localization/Localizable.xcstrings").read_text())

    def test_night_mode_is_binary_and_on_is_first(self):
        root = method(CONTROLLER, "rootSettingsPage")
        self.assertIn('.control(CWL("夜间模式")', root)
        route = method(CONTROLLER, "softwareAppearanceMenu")
        self.assertIn('let choices: [DerPlaySoftwareAppearance] = [.dark, .light]', route)
        self.assertIn('ChoiceMenu(items: [CWL("开启"), CWL("关闭")])', route)
        self.assertIn('selectedSegmentIndex = DerPlaySoftwareAppearance.saved() == .dark ? 0 : 1', route)
        self.assertIn('forKey: DerPlaySoftwareAppearance.defaultsKey', route)
        self.assertIn('self?.applySoftwareAppearance()', route)
        palette = GLASS.split('enum DerPlaySoftwareAppearance:', 1)[1].split('final class DerPlaySystemAppearanceObserver', 1)[0]
        self.assertIn('case dark, light', palette)
        self.assertIn('var style: UIUserInterfaceStyle { self == .dark ? .dark : .light }', palette)
        self.assertIn('defaults.set(Self.light.rawValue, forKey: defaultsKey)', palette)
        self.assertIn('return .light', palette)
        self.assertIn('"开启"', (ROOT / "App/Localization/Localizable.xcstrings").read_text())
        self.assertIn('"关闭"', (ROOT / "App/Localization/Localizable.xcstrings").read_text())

    def test_carplay_auto_day_night_behavior_is_untouched(self):
        appearance = method(CONTROLLER, "applyAppearance")
        self.assertIn('let night = systemAppearanceIsDark', appearance)
        self.assertNotIn('appearanceControl', appearance)
        self.assertIn('receiver.setNightMode(night)', appearance)

    def test_ios26_navigation_uses_system_bar_items_during_transitions(self):
        nav = GLASS.split('final class DerPlayGlassNavigationController', 1)[1].split('final class DerPlayPreviewMark', 1)[0]
        button = nav.split('private func glassButton(', 1)[1].split('private func installBack', 1)[0]
        self.assertIn('#if compiler(>=6.2)', button)
        self.assertIn('if #available(iOS 26.0, macCatalyst 26.0, *)', button)
        self.assertIn('UIBarButtonItem(image: image, primaryAction: primaryAction)', button)
        self.assertIn('item.accessibilityIdentifier = "derplay.navigation.glass"', button)
        self.assertIn('Let UIKit own navigation-bar glass and its transition snapshots.', button)
        self.assertNotIn('hidesSharedBackground', button)
        self.assertIn('let item = UIBarButtonItem(customView: button)', button)
        self.assertIn('glassButton(symbol: "chevron.backward"', nav)
        self.assertIn('clearTrailingPlaybackControls(on: viewController)', nav)
        self.assertIn('slot.hidesSharedBackground = true', nav)
        self.assertIn('anchor.isUserInteractionEnabled = false', nav)
        self.assertIn('applySharedAppearance(to: viewController)', nav)
        self.assertIn('installBack(on: viewController)', nav)
        self.assertIn('clearTrailingPlaybackControls(on: viewController)', nav)

if __name__ == "__main__":
    unittest.main()
