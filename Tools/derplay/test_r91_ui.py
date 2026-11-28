"""R91 source guards for user-approved settings corrections (not UIKit UI tests)."""
import unittest,json
from test_glass_ui import CONTROLLER, GLASS, SETTINGS, ROOT, method
class R91UI(unittest.TestCase):
    def test_navigation_keeps_single_material_and_both_actions(self):
        self.assertIn('UIBarButtonItem(image: image, primaryAction: primaryAction)', GLASS)
        self.assertIn('Let UIKit own navigation-bar glass and its transition snapshots.', GLASS)
        self.assertNotIn('item.hidesSharedBackground = true', method(GLASS,'glassButton'))
        self.assertIn('slot.hidesSharedBackground = true', method(GLASS,'clearTrailingPlaybackControls'))
        self.assertIn('glassButton(symbol: "chevron.backward"', GLASS)
        self.assertIn('clearTrailingPlaybackControls(on: viewController)', GLASS)
        self.assertIn('anchor.isUserInteractionEnabled = false', GLASS)
    def test_plain_text_menu(self):
        choice = SETTINGS.split('final class ChoiceMenu:',1)[1].split('final class StatusLabel:',1)[0]
        self.assertIn('UIButton.Configuration.plain()',choice)
        self.assertIn('UIAction(title: title, attributes:',choice)
        self.assertNotIn('nativeButtonConfiguration()',choice)
        self.assertIn('state: index == selectedSegmentIndex ? .on : .off',choice)
    def test_inline_routes_and_layout(self):
        self.assertIn('self.pictureRatioMenu()',method(CONTROLLER,'connectionSettingsPage'))
        self.assertIn('self.softwareAppearanceMenu()',method(CONTROLLER,'rootSettingsPage'))
        self.assertNotIn('func pictureRatioPage()',CONTROLLER)
        self.assertNotIn('func softwareAppearancePage()',CONTROLLER)
        for token in ['note.topAnchor.constraint(equalTo: safe.topAnchor)', 'pageSubtitle == nil ? 0 : 20', 'lineHeight + 24', '.systemFont(ofSize: 15, weight: .medium)', 'tableView.sectionHeaderTopPadding = 0']:
            self.assertIn(token, SETTINGS)
    def test_update_message_and_homepage(self):
        body=method(CONTROLLER,'checkForUpdates')
        for token in ['build <= installedBuild','case .missing = releaseError','暂无新版本','检查更新失败','self.showVersionDetails(release, automatic: false)']:
            self.assertIn(token,body)
        self.assertIn('throw ReleaseError.missingMetadata',(ROOT/'App/AppReleaseService.swift').read_text().split('catch ReleaseError.missing',1)[1])
        self.assertNotIn('UIApplication.shared.open(Self.projectURL)',method(CONTROLLER,'aboutLinks'))
        strings=json.loads((ROOT/'App/Localization/Localizable.xcstrings').read_text())['strings']
        for key in ['暂无新版本','当前暂无可用的新版本。','打开项目主页']:
            self.assertIn('en',strings[key]['localizations'])
