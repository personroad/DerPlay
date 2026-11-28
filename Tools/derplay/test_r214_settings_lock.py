import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER, SETTINGS, method
class SettingsLockTests(unittest.TestCase):
    def test_both_pages_share_runtime_editing_lock(self):
        self.assertIn('connectionSettingsEditable: Bool { !running && !waitingForNetwork }', CONTROLLER)
        for name in ['connectionSettingsPage','displayPage']:
            body=method(CONTROLLER,name)
            for label in ['实际输出分辨率']:
                row=next(line for line in body.splitlines() if f'CWL("{label}")' in line)
                self.assertIn('enabledWhen { [weak self] in self?.connectionSettingsEditable == true }',row)
    def test_selection_guard_and_style(self):
        self.assertIn('rows[indexPath.row].isEnabled ? indexPath : nil',SETTINGS)
        self.assertIn('guard row.isEnabled else { return }',SETTINGS)
        self.assertIn('content.secondaryTextProperties.color = .tertiaryLabel',SETTINGS)
        self.assertIn('indicator.tintColor = .tertiaryLabel',SETTINGS)
        self.assertIn('cell.accessibilityTraits.insert(.notEnabled)',SETTINGS)
    def test_dock_selection_and_fixed_preview(self):
        body=method(CONTROLLER,'dockPositionPage')
        self.assertIn('guard let self, !self.running, !self.waitingForNetwork else { return }',body)
        self.assertIn('return row.enabledWhen',body)
        self.assertIn('multiplier: 0.36',body)
        self.assertNotIn('0.46',body)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R213-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R214-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual(set(old['files']),set(lock['files']))
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift','App/SettingsUI.swift'})
