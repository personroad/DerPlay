import unittest,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
s=(root/'App/ReceiverViewController.swift').read_text()
class UI(unittest.TestCase):
 def test_removed_page(self):
  self.assertNotIn('diagnosticsPage',s); self.assertNotIn('experimentSections()',s); self.assertNotIn('CWL("诊断与实验")',s)
 def test_about(self):
  a=s.split('private func aboutDeviceSection()',1)[1].split('    // DerPlay uses',1)[0]
  self.assertIn('self.logPage()',a); self.assertIn('CWL("设备")',a); self.assertIn('CWL("MFi 证书")',a); self.assertNotIn('浏览器页面',a)
  self.assertIn('self.aboutDeviceSection().rows + self.aboutLinks())',s.split('fileprivate func aboutPage()',1)[1].split('private func aboutIdentityCard',1)[0])
 def test_ipad(self):
  a=s.split('private func iPadConnectionSections()',1)[1].split('@objc private func browserViewAreaProbeChanged',1)[0]
  self.assertIn('userInterfaceIdiom == .pad',a); self.assertIn('bluetoothSetupSwitch',a); self.assertIn('+ iPadConnectionSections()',s); self.assertNotIn('testSameDeviceTransport()',a)
 def test_translation(self):
  d=json.loads((root/'App/Localization/Localizable.xcstrings').read_text()); self.assertEqual(d['strings']['MFi 证书']['localizations']['en']['stringUnit']['value'],'MFi Certificate')
if __name__=='__main__': unittest.main(verbosity=2)
