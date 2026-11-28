import unittest, json
import candidate_lock as guard
from test_glass_ui import CONTROLLER, method
class PlaybackHapticTests(unittest.TestCase):
    def test_shared_light_feedback_after_guards_before_routing(self):
        body=method(CONTROLLER,'connectionPlaybackTapped')
        feedback='DerPlayHaptics.lightImpact()'
        self.assertEqual(body.count(feedback),1)
        self.assertLess(body.index('guard !derPlayIdentityImporting'),body.index(feedback))
        self.assertLess(body.index(feedback),body.index('if !running'))
        self.assertLess(body.index(feedback),body.index('toggleReceiver()'))
        self.assertIn(feedback,(guard.ROOT/'App/DerPlayGlassUI.swift').read_text())
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R215-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R216-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift'})
