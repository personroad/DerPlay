import unittest, hashlib, json
from test_glass_ui import ROOT, CONTROLLER, method
class R195About(unittest.TestCase):
    def test_single_card_order(self):
        page=method(CONTROLLER,'aboutPage')
        self.assertIn('self.aboutDeviceSection().rows + self.aboutLinks())',page)
        self.assertNotIn('SettingsSection(self.aboutLinks())',page)
        for name,labels in [('aboutDeviceSection',['日志','设备','MFi 证书']),('aboutLinks',['检查更新'])]:
            body=method(CONTROLLER,name)
            self.assertEqual(sorted(body.index(x) for x in labels),[body.index(x) for x in labels])
    def test_previous_lock_preserved(self):
        old=(ROOT/'DerPlay/R194-candidate-lock.json').read_bytes(); prev=json.loads(old); new=json.loads((ROOT/'DerPlay/R195-candidate-lock.json').read_text())
        self.assertEqual(hashlib.sha256(old).hexdigest(),new['previous_lock_sha256'])
        self.assertEqual(prev['methods'],new['methods'])
        for name,entry in prev['files'].items():
            if name=='App/ReceiverViewController.swift':
                self.assertEqual(entry['candidate_sha256'],new['files'][name]['r194_sha256'])
                self.assertEqual(entry['r157_sha256'],new['files'][name]['r157_sha256'])
            else: self.assertEqual(entry,new['files'][name])
