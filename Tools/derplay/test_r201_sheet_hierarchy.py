import unittest
from test_glass_ui import GLASS, CONTROLLER, method

class SheetHierarchyTests(unittest.TestCase):
    def test_no_early_install(self):
        body = method(GLASS, 'captureGeometry')
        self.assertIn('homeSlot.window === window', body)
        self.assertIn('homeSlot.bounds.width > 0', body)
        self.assertLess(body.index('homeSlot.window === window'), body.index('homeSlot.convert'))
    def test_common_ancestor_before_constraints(self):
        body = method(GLASS, 'installContent')
        self.assertLess(body.index('panel.insertSubview(content'), body.index('NSLayoutConstraint.activate(contentConstraints)'))
        self.assertIn('addSubview(panel)', GLASS)
        self.assertIn('addSubview(button)', GLASS)
    def test_layout_retry_and_dismissal(self):
        self.assertIn('render(progress)', GLASS)
        body = method(GLASS, 'uninstallContent')
        self.assertLess(body.index('NSLayoutConstraint.deactivate(contentConstraints)'), body.index('content.removeFromSuperview()'))
        self.assertIn('keyboardLimit?.isActive = false', body)
        self.assertIn('layer.installContent(navigation.view)', method(CONTROLLER, 'prepareConnectionLayer'))
