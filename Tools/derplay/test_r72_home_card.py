"""Source checks for enlarged home card; not a rendered layout test."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[2]
class HomeCardTests(unittest.TestCase):
    def test_home_card_scale_and_wrapping(self):
        source = (ROOT/'App/DerPlayGlassUI.swift').read_text()
        row = source.split('private func menuRow(',1)[1].split('private var rows:',1)[0]
        for token in ['.font(.system(size: 19)).frame(width: 24)', 'Text(title).font(.body).fixedSize(horizontal: false, vertical: true)', 'Text(value).font(.footnote)', '.multilineTextAlignment(.trailing).fixedSize(horizontal: false, vertical: true)', '.frame(minHeight: 58)', 'Button(action: action)']:
            self.assertIn(token, row)
        self.assertNotIn('.lineLimit(1)', row)
    def test_preview_footer_and_actions_preserved(self):
        source = (ROOT/'App/DerPlayGlassUI.swift').read_text()
        for token in ['menuRow(CWL("通用设置"), symbol: "gearshape", action: settings)', 'menuRow(CWL("连接模式"), symbol: "car", value: state.mode, action: connection)', 'Text(line).font(.subheadline)', '.disabled(!state.airPlayPickerReady)', '.padding(.horizontal, 16)']:
            self.assertIn(token, source)
        controller = (ROOT/'App/ReceiverViewController.swift').read_text()
        for token in ['scroll.bottomAnchor.constraint(equalTo: footer.topAnchor)', 'footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)', 'host.sizingOptions = [.intrinsicContentSize]', 'multiplier: displayAspectHeight']:
            self.assertIn(token, controller)
