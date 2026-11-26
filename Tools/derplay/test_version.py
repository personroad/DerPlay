"""Build identity checks using synthetic IPA metadata, not a real app."""
import pathlib, plistlib, struct, tempfile, unittest, zipfile
from verify_ipa import verify
ROOT = pathlib.Path(__file__).resolve().parents[2]
class VersionTests(unittest.TestCase):
    def test_source_version(self):
        info=plistlib.loads((ROOT/'App/Info.plist').read_bytes())
        self.assertEqual(info['CFBundleShortVersionString'],'0.0.1')
        self.assertRegex(info['CFBundleVersion'],r'^[1-9][0-9]*$')
    def test_ipa_versions(self):
        with tempfile.TemporaryDirectory() as d:
            p=pathlib.Path(d)/'test.ipa'
            for version,build,valid in [('0.0.1','2',True),('0.0.2','2',False),('0.0.1','1',False),('0.0.1','2-beta',False)]:
                with self.subTest(version=version,build=build):
                    with zipfile.ZipFile(p,'w') as z:
                        z.writestr('Payload/Test.app/Info.plist',plistlib.dumps(dict(CFBundleIdentifier='com.derplay.app',CFBundleDisplayName='DerPlay',CFBundlePackageType='APPL',CFBundleExecutable='Test',CFBundleShortVersionString=version,CFBundleVersion=build)))
                        z.writestr('Payload/Test.app/Test',struct.pack('<II',0xfeedfacf,0x0100000c)+bytes(24))
                    if valid: self.assertEqual(verify(p,expected_build='2')['build'],'2')
                    else:
                        with self.assertRaises(ValueError): verify(p,expected_build='2')
if __name__=='__main__': unittest.main(verbosity=2)
