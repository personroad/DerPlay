import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER,method
class HapticPreferenceTests(unittest.TestCase):
    def test_order_and_switch(self):
        body=method(CONTROLLER,'rootSettingsPage')
        self.assertLess(body.index('CWL("画中画")'),body.index('CWL("触感反馈")'))
        self.assertLess(body.index('CWL("触感反馈")'),body.index('CWL("MFi 证书管理")'))
        body=method(CONTROLLER,'hapticFeedbackSwitch')
        self.assertIn('UISwitch()',body)
        self.assertIn('toggle.isOn = DerPlayHaptics.isEnabled',body)
        self.assertIn('DerPlayHaptics.isEnabled = toggle.isOn',body)
    def test_shared_guard(self):
        glass=(guard.ROOT/'App/DerPlayGlassUI.swift').read_text()
        self.assertIn('as? Bool ?? true',glass)
        self.assertIn('UserDefaults.standard.set(newValue, forKey: defaultsKey)',glass)
        self.assertIn('guard isEnabled else { return }',glass)
        self.assertEqual(glass.count('UIImpactFeedbackGenerator(style: .light).impactOccurred()'),1)
        self.assertEqual(CONTROLLER.count('DerPlayHaptics.lightImpact()'),3)
        self.assertNotIn('UIImpactFeedbackGenerator(',CONTROLLER)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R216-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R217-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift','App/DerPlayGlassUI.swift','App/Localization/Localizable.xcstrings'})
