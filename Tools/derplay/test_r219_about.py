import unittest
from test_glass_ui import CONTROLLER,method
class R219About(unittest.TestCase):
    def test_optional_acknowledgments_removed(self):
        page=method(CONTROLLER,'aboutPage')
        for token in ['开源致谢','原项目 CarWithin','原项目贡献者','ContributionsViewController']:
            self.assertNotIn(token,page)
        for token in ['AGPL-3.0','Copyright © 2026 xmz28','self.aboutLinks()']:
            self.assertIn(token,page)
