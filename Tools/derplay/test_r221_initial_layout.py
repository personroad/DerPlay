import unittest,json
import candidate_lock as guard
from test_glass_ui import CONTROLLER, GLASS, method
class InitialLayoutTests(unittest.TestCase):
    def test_root_layout_reconciles_sibling_slot(self):
        body=method(CONTROLLER,'viewDidLayoutSubviews')
        self.assertIn('connectionControlLayer?.reconcileSettledLayout()',body)
        self.assertIn('setNeedsLayout()',method(GLASS,'didMoveToWindow'))
        body=method(GLASS,'reconcileSettledLayout')
        self.assertIn('if animator != nil || dragging',body)
        self.assertIn('UIView.performWithoutAnimation',body)
        self.assertLess(body.index('preparePanelGeometry()'),body.index('render(progress)'))
    def test_initial_frame_before_visibility(self):
        for name in ['setExpanded','drag']:
            body=method(GLASS,name)
            self.assertLess(body.index('UIView.performWithoutAnimation'),body.index('panel.isHidden = false'))
            self.assertLess(body.index('render(progress)'),body.index('backdrop.isHidden = false'))
            self.assertLess(body.index('guard motionGeometry != nil'),body.index('panel.isHidden = false'))
        self.assertIn('backdrop.frame = geometry.bounds',method(GLASS,'render'))
    def test_natural_modal_coverage(self):
        for name in ['revealSettings','settingsDismissed']:
            self.assertNotIn('startButton.isHidden',method(CONTROLLER,name))
        self.assertIn('presentedViewController == nil',method(CONTROLLER,'connectionPlaybackTapped'))
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R220-candidate-lock.json'; old=json.loads(p.read_text()); lock=json.loads((guard.ROOT/'DerPlay/R221-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift','App/DerPlayGlassUI.swift'})
