"""R138 browser-only home status address copy regression checks."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTROLLER = (ROOT / "App/ReceiverViewController.swift").read_text()
DASHBOARD = (ROOT / "App/DerPlayGlassUI.swift").read_text()
APP_CATALOG = (ROOT / "App/Localization/Localizable.xcstrings").read_text()
DOC_CATALOG = (ROOT / "docs/localization/en/Localizable.xcstrings").read_text()
TRANSLATIONS = (ROOT / "docs/localization/en/translations.json").read_text()
TSV = (ROOT / "docs/localization/en/translations.tsv").read_text()

class BrowserAddressCopyTests(unittest.TestCase):
    def test_only_browser_video_session_projects_address(self):
        for condition in (
            'outputMode == .browser',
            'videoOutputSwitch.isOn',
            'running',
            'displayedVideo',
            'statusLabel.text == CWL("CarPlay窗口已开启")',
        ):
            self.assertIn(condition, CONTROLLER)
        self.assertIn(r'browserAddress.flatMap { address in browserPort.map { "\(address):\($0)" } }', CONTROLLER)

    def test_visible_copy_line_has_full_http_address(self):
        self.assertIn('CWL("访问地址：{1}"', CONTROLLER)
        self.assertIn('Access address: {1}', APP_CATALOG)
        projection = CONTROLLER.split('let canCopyBrowserAddress', 1)[1].split('let showAirPlay', 1)[0]
        self.assertIn('http://', projection)
        self.assertNotIn('https://', projection)

    def test_button_is_after_second_status_line_or_last_available(self):
        self.assertIn('if index == min(1, state.statusLines.count - 1),', DASHBOARD)
        self.assertIn('let address = state.browserCopyAddress', DASHBOARD)
        self.assertIn('copyBrowserAddress(address)', DASHBOARD)
        row = DASHBOARD.split('let label = state.browserCopyAddressLabel',1)[1].split('if state.showsAirPlayPicker',1)[0]
        self.assertNotIn('.underline()', row)
        self.assertIn('.font(.subheadline)', row)
        self.assertIn('.foregroundStyle(.secondary)', row)

    def test_clipboard_receives_only_ip_and_port(self):
        method = CONTROLLER.split('private func copyBrowserAccessAddress', 1)[1].split('private func makeDerPlayConnectionPanel', 1)[0]
        self.assertIn('UIPasteboard.general.string = address', method)
        self.assertNotIn('UIPasteboard.general.string = label', method)
        self.assertNotIn('UIPasteboard.general.string = "点击复制访问地址:', method)

    def test_all_localization_sources_include_the_template(self):
        for source in (APP_CATALOG, DOC_CATALOG, TRANSLATIONS, TSV):
            self.assertIn('点击复制访问地址:{1}', source)
            self.assertIn('Tap to copy access address:{1}', source)

if __name__ == "__main__":
    unittest.main(verbosity=2)
