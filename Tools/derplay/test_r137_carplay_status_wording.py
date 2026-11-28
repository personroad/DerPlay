"""R137 user-approved CarPlay status wording regression checks."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / "App/ReceiverViewController.swift").read_text()
APP_CATALOG = (ROOT / "App/Localization/Localizable.xcstrings").read_text()
DOC_CATALOG = (ROOT / "docs/localization/en/Localizable.xcstrings").read_text()
TRANSLATIONS = (ROOT / "docs/localization/en/translations.json").read_text()
TSV = (ROOT / "docs/localization/en/translations.tsv").read_text()
class CarPlayStatusWordingTests(unittest.TestCase):
    def test_runtime_trigger_unchanged_with_new_copy(self):
        self.assertEqual(SOURCE.count('CWL("CarPlay窗口已开启")'), 2)
        self.assertNotIn('CWL("正在显示 CarPlay")', SOURCE)
        self.assertIn('if !self.displayedVideo {', SOURCE)
        self.assertIn('self.displayedVideo = true; self.statusLabel.text = CWL("CarPlay窗口已开启")', SOURCE)
        self.assertIn('statusLabel.text == CWL("CarPlay窗口已开启")', SOURCE)
    def test_localization_catalogs_are_consistent(self):
        for text in (APP_CATALOG, DOC_CATALOG, TRANSLATIONS, TSV):
            self.assertIn('CarPlay窗口已开启', text)
            self.assertIn('CarPlay window is open', text)
            self.assertNotIn('正在显示 CarPlay', text)
            self.assertNotIn('Displaying CarPlay', text)
if __name__ == "__main__": unittest.main()
