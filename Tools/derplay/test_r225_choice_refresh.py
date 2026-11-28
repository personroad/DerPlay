import json, unittest
import candidate_lock as guard
from test_glass_ui import CONTROLLER, SETTINGS, method

class ChoiceRefreshTests(unittest.TestCase):
    def test_connection_display_selection_keeps_source_attached(self):
        body = method(CONTROLLER, 'displaySettingChanged')
        self.assertIn('page.title == CWL("连接模式")', body)
        self.assertIn('page.refreshDetails()', body)
        self.assertIn('else {\n            reloadVisibleSettings()', body)
        self.assertIn('saveDisplaySettings()', body)
        self.assertIn('updateVideoAspect()', body)
        self.assertNotIn('reloadData()', method(SETTINGS, 'refreshDetails'))
        self.assertIn('for (indexPath, cell) in cells', method(SETTINGS, 'refreshDetails'))
    def test_resolution_detail_is_live(self):
        body = method(CONTROLLER, 'connectionSettingsPage')
        self.assertIn('detail: { [unowned self] in\n                    let previewPlan = self.planDisplay', body)
        self.assertIn('return self.actualOutputResolutionLabel(for: previewPlan)', body)
    def test_no_redundant_selection_refresh_and_locked_action_guard(self):
        self.assertIn('if selectedSegmentIndex != oldValue { refresh() }', SETTINGS)
        self.assertIn('guard let self, self.isEnabled, self.items.indices.contains(index)', SETTINGS)
        self.assertIn('!self.disabledItems.contains(index)', SETTINGS)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R222-candidate-lock.json'; old=json.loads(p.read_text())
        lock=json.loads((guard.ROOT/'DerPlay/R225-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/SettingsUI.swift','App/ReceiverViewController.swift'})
