import hashlib
import io
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path
from verify_delivery import verify, PRIVATE_NAMES


def pack(entries):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, data in entries.items():
            z.writestr(name, data)
    return buf.getvalue()


def manifest(entries):
    return ''.join(f'{hashlib.sha256(data).hexdigest()}  {name}\n' for name, data in entries.items()).encode()


def fixture(extra=None, mismatch=False, bad_manifest=False):
    source = {'App/Info.plist': plistlib.dumps({'CFBundleVersion': '17'}), 'App/example.swift': b'original', 'LICENSE': b'license', 'Package.swift': b'package'}
    private = {'project/'+n: v for n,v in source.items()}
    private.update({'project/'+n: b'doc' for n in PRIVATE_NAMES})
    if mismatch:
        private['project/App/example.swift'] = b'changed'
    source.update(extra or {})
    deploy = {'DerPlay-0.0.1-build17-R92-source.zip': pack(source), 'deploy.cmd': b'cmd', 'deploy.sh': b'sh', 'README.txt': b'readme'}
    deploy['SHA256.txt'] = manifest(deploy)
    outer = {'DerPlay-build17-R92-all-in-one.zip': pack(deploy), 'DerPlay-build17-R92-private.zip': pack(private), 'DerPlay-build17-R92-test-logs.zip': pack({'test.log': b'example'})}
    outer['SHA256.txt'] = manifest(outer)
    outer['README-交付说明.txt'] = b'readme'
    if bad_manifest:
        outer['DerPlay-build17-R92-test-logs.zip'] = pack({'test.log': b'changed'})
    return pack(outer)


class DeliveryVerifierTests(unittest.TestCase):
    def check(self, **kwargs):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)/'bundle.zip'
            p.write_bytes(fixture(**kwargs))
            return verify(p)

    def test_valid(self):
        self.assertTrue(self.check().startswith('PASS'))

    def test_private_path(self):
        with self.assertRaisesRegex(ValueError, 'private path'):
            self.check(extra={'AI_HANDOVER.md': b'private'})

    def test_cache(self):
        with self.assertRaisesRegex(ValueError, 'private path'):
            self.check(extra={'Tools/__pycache__/a.pyc': b'cache'})

    def test_mismatch(self):
        with self.assertRaisesRegex(ValueError, 'runtime mismatch'):
            self.check(mismatch=True)

    def test_digest(self):
        with self.assertRaisesRegex(ValueError, 'SHA256 mismatch'):
            self.check(bad_manifest=True)

    def test_unsafe_path(self):
        with self.assertRaisesRegex(ValueError, 'unsafe'):
            self.check(extra={'../bad': b'bad'})
