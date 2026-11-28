import json, unittest
import candidate_lock as guard
from test_glass_ui import CONTROLLER, method

class ResolutionLabelTests(unittest.TestCase):
    def test_label_only(self):
        for name in ['connectionSettingsPage','displayPage']:
            body=method(CONTROLLER,name)
            self.assertIn('CWL("默认分辨率")',body)
            self.assertNotIn('CWL("清晰度")',body)
            self.assertIn('resolutionControl',body)
        self.assertIn('CWL("实际输出分辨率")',method(CONTROLLER,'connectionSettingsPage'))
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R225-candidate-lock.json'
        old=json.loads(p.read_text())
        lock=json.loads((guard.ROOT/'DerPlay/R226-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift','App/Localization/Localizable.xcstrings'})
