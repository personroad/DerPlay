import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER,SETTINGS,method
class RuntimeEditingNoticeTests(unittest.TestCase):
    def test_notice_is_state_gated_and_does_not_mutate(self):
        body=method(SETTINGS,'showRuntimeEditingNotice')
        for token in ['runtimeEditingLocked?() == true','presentedViewController == nil','请停止 CarPlay 后再修改','preferredStyle: .alert']:
            self.assertIn(token,body)
        self.assertIn('self?.connectionSettingsEditable == false',method(CONTROLLER,'page'))
        self.assertIn('guard row.isEnabled else { return }',SETTINGS)
    def test_disabled_control_and_field_taps(self):
        body=method(SETTINGS,'hasLockedControl')
        self.assertIn('(view as? UIControl)?.isEnabled == false',body)
        self.assertIn('($0 as? UITextField)?.isEnabled == false',body)
        self.assertIn('hasLockedControl(sections[indexPath.section].rows[indexPath.row])',method(SETTINGS,'lockedControlTapped'))
    def test_dock_entry_and_read_only_info(self):
        for name in ['connectionSettingsPage','displayPage']:
            row=next(line for line in method(CONTROLLER,name).splitlines() if '.page(CWL("Dock 栏")' in line)
            self.assertNotIn('enabledWhen',row)
        self.assertIn('case .action, .page: showRuntimeEditingNotice()',SETTINGS)
        self.assertIn('return row.enabledWhen',method(CONTROLLER,'dockPositionPage'))
    def test_protection_lineage(self):
        p=guard.ROOT/'DerPlay/R219-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R220-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift','App/SettingsUI.swift','App/Localization/Localizable.xcstrings'})
