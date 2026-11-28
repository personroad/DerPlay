import json, unittest
import candidate_lock as guard
from test_glass_ui import GLASS, method
class TransitionTests(unittest.TestCase):
    def test_duplicate_target_does_not_interrupt(self):
        body=method(GLASS,'setExpanded')
        self.assertLess(body.index('if animator != nil && targetOpen == open { return }'),body.index('interrupt()'))
        self.assertLess(body.index('interrupt()'),body.index('targetOpen = open'))
        self.assertIn('guard !dragging else { return }',body)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R229-candidate-lock.json'; old=json.loads(p.read_text()); new=guard.LOCK
        self.assertEqual(guard.digest(p.read_bytes()),new['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],new['methods'])
        self.assertEqual(old['additional_geometry_files'],new['additional_geometry_files'])
        self.assertEqual(set(old['files']),set(new['files']))
        self.assertEqual({n for n in old['files'] if old['files'][n]!=new['files'][n]}, {'App/DerPlayGlassUI.swift'})
