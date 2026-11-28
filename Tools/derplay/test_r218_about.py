import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER,method
class R218About(unittest.TestCase):
    def test_only_update_link_remains(self):
        body=method(CONTROLLER,'aboutLinks')
        self.assertIn('self.checkForUpdates()',body)
        self.assertNotIn('打开项目主页',body)
        self.assertNotIn('.externalLink(',body)
        page=method(CONTROLLER,'aboutPage')
        for token in ['AGPL-3.0','Copyright © 2026 xmz28']:
            self.assertIn(token,page)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R218-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R219-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift'})
