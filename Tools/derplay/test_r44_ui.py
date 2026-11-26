import unittest
from test_glass_ui import CONTROLLER, SETTINGS, method, ROOT
class R44UI(unittest.TestCase):
    def test_menu(self):
        s=method(CONTROLLER,'interconnectPage')
        tokens=['row("本机 CarPlay"','row(HeadUnitOutput.browser.title','row(HeadUnitOutput.airPlay.title','plannedRow("derplay.iccoa.direct"','items.append(row("百度 CarLife"','plannedRow("derplay.easyconnection"']
        self.assertEqual([s.index(t) for t in tokens],sorted(s.index(t) for t in tokens))
        self.assertNotIn('SettingsSection("开发中"',s)
    def test_about(self):
        s=method(CONTROLLER,'aboutLinks'); tokens=['使用说明','版本记录','检查更新','DerPlay GitHub Releases']; self.assertEqual([s.index(t) for t in tokens],sorted(s.index(t) for t in tokens)); self.assertNotIn('GitHub 项目',s)
        s=method(CONTROLLER,'aboutPage'); self.assertIn('centered: true',s); self.assertIn('AGPL-3.0',s); self.assertNotIn('关注上游作者',s); self.assertNotIn('支持上游作者',s)
    def test_local_geometry(self):
        s=method(CONTROLLER,'updateInlineSurfaceGeometry'); self.assertIn('rotationAngle: .pi / 2',s); self.assertIn('releaseAllTouches()',s); self.assertIn('portrait ? inlineVideoContainer.heightAnchor',s)
        self.assertIn('requestGeometryUpdate',method(CONTROLLER,'showFullscreen')); self.assertIn('interfaceOrientations: .portrait',method(CONTROLLER,'hideFullscreen'))
        self.assertIn('topViewController?.supportedInterfaceOrientations',(ROOT/'App/AppDelegate.swift').read_text())
