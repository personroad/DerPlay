"""R143 source guards; these do not replace an iOS menu interaction test."""
import json, unittest
from test_glass_ui import CONTROLLER, GLASS, ROOT, method

class InterconnectMenuTests(unittest.TestCase):
    def test_two_home_entries_and_current_value(self):
        rows=GLASS.split('private var rows:',1)[1].split('if !state.statusLines.isEmpty',1)[0]
        self.assertEqual(rows.count('menuRow('),2)
        self.assertIn('menuRow(CWL("通用设置")',rows)
        self.assertIn('menuRow(CWL("连接模式"), symbol: "car", value: state.mode, action: connection)',rows)
        self.assertNotIn('modes: {',method(CONTROLLER,'makeDerPlayConnectionPanel'))
    def test_first_card_and_original_settings(self):
        body=method(CONTROLLER,'connectionSettingsPage')
        self.assertIn('page(CWL("连接模式"), firstCardTopSpacing: 12)',body)
        self.assertIn('return [SettingsSection(networkRows), SettingsSection(CWL("CarPlay 设置"), footer: editingLockedFooter, carPlayRows)]',body)
        self.assertIn('SettingsRow.page(CWL("互联协议")',body)
        self.assertIn('self.interconnectPage()',body)
        self.assertIn('if needsNetworkDetails',body)
        self.assertIn('if outputMode == .browser && videoOutputSwitch.isOn',body)
    def test_native_child_selection_page(self):
        page=method(CONTROLLER,'interconnectPage')
        self.assertIn('SettingsSection(self.interconnectRows())',page)
        for token in ['interconnectModeMenu()', 'presentInterconnectModePopover', 'DerPlayInterconnectMenuPopover']:
            self.assertNotIn(token,CONTROLLER)
    def test_selection_returns_to_parent(self):
        rows=method(CONTROLLER,'interconnectRows')
        self.assertLess(rows.index('self.headUnitOutputChanged()'),rows.index('navigation.popViewController(animated: true)'))
        self.assertLess(rows.index('self.videoOutputToggled()'),rows.index('navigation.popViewController(animated: true)'))
        self.assertNotIn('closeGlassSettings',rows)
    def test_disabled_and_planned_choices_retained(self):
        rows=method(CONTROLLER,'interconnectRows')
        for token in ['!self.wifiAddSavePending','if locked || wifiAddSavePending {','let locked = running || waitingForNetwork','plannedRow("derplay.iccoa.direct"','plannedRow("derplay.easyconnection"','HeadUnitOutput.menuOrder.filter']:
            self.assertIn(token,rows)
    def test_new_localization_keys(self):
        for path in ['App/Localization/Localizable.xcstrings','docs/localization/en/Localizable.xcstrings']:
            strings=json.loads((ROOT/path).read_text())['strings']
            for k in ['连接模式','互联协议','CarPlay 设置','Wi-Fi 网络']:
                self.assertEqual(strings[k]['localizations']['zh-Hans']['stringUnit']['value'],k)
                self.assertTrue(strings[k]['localizations']['en']['stringUnit']['value'])
