import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER, method
class DockNavigationTests(unittest.TestCase):
    def test_dock_entry_remains_navigable(self):
        for name in ['connectionSettingsPage','displayPage']:
            row=next(line for line in method(CONTROLLER,name).splitlines() if '.page(CWL("Dock 栏")' in line)
            self.assertNotIn('enabledWhen',row)
            self.assertIn('self.dockPositionPage()',row)
    def test_position_mutation_still_locked(self):
        body=method(CONTROLLER,'dockPositionPage')
        self.assertIn('guard let self, !self.running, !self.waitingForNetwork else { return }',body)
        self.assertIn('return row.enabledWhen { [weak self] in self?.connectionSettingsEditable == true }',body)
    def test_protection_scope(self):
        lock=json.loads((guard.ROOT/'DerPlay/R215-candidate-lock.json').read_text()); p=guard.ROOT/'DerPlay/R214-candidate-lock.json'; old=json.loads(p.read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift'})
