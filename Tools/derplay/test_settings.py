"""Source guards for DerPlay settings branding and identity boundary."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
class SettingsTests(unittest.TestCase):
    def setUp(self):
        self.s = (ROOT/'App/ReceiverViewController.swift').read_text()
    def test_brand_and_release_route(self):
        self.assertIn('https://github.com/personroad/DerPlay', self.s)
        self.assertIn('name.text = "DerPlay"', self.s)
        self.assertIn('UIApplication.shared.open(Self.releasesURL)', self.s)
        self.assertIn('Copyright © 2026 xmz28', self.s)
    def test_root_and_upstream_support(self):
        root = self.s.split('fileprivate func rootSettingsPage()',1)[1].split('private func backgroundSettingsPage()',1)[0]
        for item in ['MFi 身份管理','后台与画中画','软件外观','诊断与实验','关于']:
            self.assertIn(item, root)
        connection = self.s.split('private func connectionSettingsPage()',1)[1].split('private func pictureRatioPage()',1)[0]
        for item in ['画面比例','仪表设置','HTTPS 设置','Wi-Fi 与网络','电池与 BMS']:
            self.assertIn(item, connection)
        self.assertNotIn('Wi-Fi 预设',connection)
        self.assertNotIn('电池与 BMS',root)
        self.assertNotIn('DeveloperSupportViewController()', root)
        self.assertIn('DeveloperSupportViewController()', self.s)
    def test_identity_is_not_bypass(self):
        page = self.s.split('private func derPlayIdentityPage()',1)[1].split('fileprivate func aboutPage()',1)[0]
        self.assertIn('guard !self.running, !self.waitingForNetwork', page)
        self.assertIn('picker.allowsMultipleSelection = true', page)
        self.assertIn('forOpeningContentTypes: hints + [.data], asCopy: true', page)
        self.assertIn('DerPlayIdentityImport.recognize', page)
        self.assertIn('Accessor' + 'yIdentityStore.importMaterial', page)
        self.assertIn('Accessor' + 'yIdentityStore.clearIdentity()', page)
        self.assertIn('derPlayIdentityImporting', page)
        self.assertIn('controller === derPlayIdentityPicker', self.s)
        cancel = self.s.split('func documentPickerWasCancelled(', 1)[1].split('func documentPicker(', 1)[0]
        self.assertIn('controller === derPlayIdentityPicker', cancel)
        self.assertIn('derPlayIdentityPicker = nil', cancel)
        self.assertIn('chooseHTTPSCertificate()', self.s)
        self.assertIn('AccessoryIdentityStore.load()', page)
        self.assertNotIn('importFromDocuments()', page)
        self.assertIn('startButton.isEnabled = identity != nil', self.s)
    def test_identity_copy_batch_and_diagnostics(self):
        page = self.s.split('private func derPlayIdentityPage()',1)[1].split('fileprivate func aboutPage()',1)[0]
        self.assertEqual(page.count('UIDocumentPickerViewController('), 1)
        callback = self.s.split('func documentPicker(_ controller:',1)[1].split('guard let url = urls.first',1)[0]
        self.assertIn('guard (2...3).contains(urls.count)', callback)
        self.assertLess(callback.index('urls.map(DerPlayIdentityImport.readCopiedFile)'), callback.index('controller.dismiss(animated: true)'))
        self.assertIn('UTType(filenameExtension: $0, conformingTo: .data)', page)
        self.assertIn('["p7b", "pk8", "cer", "x963"]', page)
        self.assertIn('Result<[Data], Error>', callback)
        self.assertIn('文件读取完成', page)
        self.assertIn('已收到系统文件选择回调', self.s)
        reader = (ROOT/'App/DerPlayIdentityImport.swift').read_text().split('static func readCopiedFile',1)[1].split('static func recognize',1)[0]
        self.assertNotIn('NSFileCoordinator', reader)
        self.assertIn('65_536', reader)
        self.assertIn('stopAccessingSecurityScopedResource()', reader)
    def test_identity_atomic_store_and_clear(self):
        store=(ROOT/'App/AccessoryIdentityStore.swift').read_text()
        vault=(ROOT/'App/DerPlayIdentityImport.swift').read_text()
        self.assertIn('try DerPlayIdentityVault.write(.init(material: material))', store)
        self.assertIn('try DerPlayIdentityVault.write(.init(material: nil))', store)
        self.assertIn('guard try DerPlayIdentityVault.read() == nil', store)
        self.assertIn('SecItemUpdate', vault)
        self.assertIn('kSecAttrAccessibleWhenUnlockedThisDeviceOnly', vault)
        self.assertNotIn('SecItemDelete', vault)
if __name__ == '__main__': unittest.main(verbosity=2)
