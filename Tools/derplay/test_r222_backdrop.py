import json, unittest
import candidate_lock as guard
from test_glass_ui import GLASS, method
class BackdropTests(unittest.TestCase):
    def test_backdrop_visual_separate_from_hit_surface(self):
        self.assertIn('backdropTint.isUserInteractionEnabled = false',GLASS)
        body=method(GLASS,'render')
        self.assertIn('backdropTint.alpha = 0.24 * progress',body)
        self.assertIn('backdropTint.frame = backdrop.bounds',body)
        self.assertNotIn('backdrop.alpha =',body)
    def test_settle_without_extra_animation(self):
        body=method(GLASS,'setExpanded')
        self.assertIn('UIView.performWithoutAnimation {\n                self.preparePanelGeometry()',body)
        self.assertIn('self.render(destination)',body)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R221-candidate-lock.json'; old=json.loads(p.read_text())
        self.assertEqual(guard.digest(p.read_bytes()),guard.LOCK['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],guard.LOCK['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=guard.LOCK['files'][n]}, {'App/DerPlayGlassUI.swift'})
