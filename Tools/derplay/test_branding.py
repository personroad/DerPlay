import json, pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
class BrandingTests(unittest.TestCase):
    def test_browser_both_languages(self):
        for name, status in [('BrowserReceiverPage.swift','正在连接 DerPlay'),('Localization/Receiver.en.html','Connecting to DerPlay')]:
            text=(ROOT/'App'/name).read_text()
            self.assertIn('<title>DerPlay</title>',text)
            self.assertIn(status,text)
            self.assertNotIn('<title>CarWithin</title>',text)
            self.assertIn('if(m.page!==PAGE_VERSION){location.reload();return}',text)
        self.assertIn('"1.0.3-"',(ROOT/'App/BrowserReceiverPage.swift').read_text())
    def test_localized_names(self):
        loc=(ROOT/'App/Localization/Localizable.xcstrings').read_text()
        json.loads(loc)
        self.assertNotIn('CarWithin',loc)
        for key in ['DerPlay HTTPS 根证书','已连接 DerPlay，正在等待关键帧']:
            self.assertIn(key,loc)
    def test_keep_compatibility_identifiers(self):
        tls=(ROOT/'App/LocalTLSIdentity.swift').read_text()
        self.assertIn('com.carwithin.browser-https.root',tls)
        self.assertIn('CarWithin HTTPS Root',tls)
        self.assertIn('<title>DerPlay HTTPS</title>',tls)
        self.assertIn('"appVersionFingerPrint": "carwithin"',(ROOT/'App/PxcConnection.swift').read_text())
        self.assertIn('"CarWithin1,1"',(ROOT/'App/CarPlayInfo.swift').read_text())
if __name__=='__main__': unittest.main()
