import json
import unittest
from pathlib import Path
from test_glass_ui import method
ROOT = Path(__file__).resolve().parents[2]
class ConnectionSubtitleTests(unittest.TestCase):
    def test_connection_page_has_no_subtitle(self):
        source = (ROOT/'App/ReceiverViewController.swift').read_text()
        body = method(source, 'connectionSettingsPage')
        self.assertIn('page(CWL("连接模式"), firstCardTopSpacing: 12)', body)
        self.assertNotIn('connectionSettingsSubtitle', source)
        self.assertNotIn('subtitle:', body)
        self.assertEqual(source.count('firstCardTopSpacing: 12'), 1)
        ui = (ROOT/'App/SettingsUI.swift').read_text()
        self.assertIn('if firstCardTopSpacing != nil { tableView.sectionHeaderTopPadding = 0 }', ui)
        self.assertIn('if section == 0, sections[section].header == nil, let spacing = firstCardTopSpacing { return spacing }', ui)
    def test_header_style_and_translation(self):
        source = (ROOT/'App/SettingsUI.swift').read_text()
        for marker in ['note.font = .systemFont(ofSize: 12)', 'note.textColor = .secondaryLabel', 'note.textAlignment = .center', 'view.addSubview(note)', 'contentTop = note.bottomAnchor']:
            self.assertIn(marker,source)
        strings = json.loads((ROOT/'App/Localization/Localizable.xcstrings').read_text())['strings']
        self.assertIn('en',strings['调整 {1} 默认设置']['localizations'])
    def test_selected_protocol_names(self):
        source = (ROOT/'App/ReceiverViewController.swift').read_text()
        for title in ['极核 6.2 寸','极核 SE+ 5/5.5 寸','极核 AE2 Pro 5 寸','春风 5 寸','春风 6.2 寸','九号 4.3 寸','九号 5 寸','九号 7 寸','台铃 4.3 寸']:
            self.assertIn('CWL("'+title+'")', source)
        strings = json.loads((ROOT/'App/Localization/Localizable.xcstrings').read_text())['strings']
        for key in ['调整 {1} 默认设置','调整{1}默认设置','调整本机 CarPlay 默认设置']:
            self.assertEqual(strings[key]['localizations']['zh-Hans']['stringUnit']['value'],key)
            self.assertIn('en',strings[key]['localizations'])
    def test_about_and_fixed_header_spacing(self):
        source = (ROOT/'App/ReceiverViewController.swift').read_text()
        card = method(source,'aboutIdentityCard')
        self.assertIn('card.setCustomSpacing(8, after: name)',card)
        self.assertIn('card.setCustomSpacing(8, after: introduction)',card)
        ui = (ROOT/'App/SettingsUI.swift').read_text()
        self.assertIn('note.topAnchor.constraint(equalTo: safe.topAnchor)',ui)
        self.assertIn('pageSubtitle == nil ? 0 : 20',ui)
        self.assertIn('label.centerYAnchor.constraint(equalTo: container.centerYAnchor)',ui)
        self.assertNotIn('label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -8)',ui)
