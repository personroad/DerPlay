import hashlib
from pathlib import Path
import tempfile
import unittest
from audit_checkpoint import audit


class CheckpointAuditTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.digest = hashlib.sha256(b'original').hexdigest()
        (self.root / 'file.txt').write_bytes(b'original')
        self.manifest = self.root / 'MANIFEST.sha256'
        self.manifest.write_text(f'{self.digest}  file.txt\n')

    def test_clean(self):
        self.assertEqual(audit(self.root), {'matched': ['file.txt'], 'mismatched': [], 'missing': [], 'unlisted': []})

    def test_modified_is_read_only(self):
        (self.root / 'file.txt').write_bytes(b'changed')
        before = self.manifest.read_bytes()
        self.assertEqual(audit(self.root)['mismatched'][0]['path'], 'file.txt')
        self.assertEqual(self.manifest.read_bytes(), before)

    def test_missing_and_extra(self):
        (self.root / 'file.txt').unlink()
        (self.root / 'extra').touch()
        result = audit(self.root)
        self.assertEqual(result['missing'], ['file.txt'])
        self.assertEqual(result['unlisted'], ['extra'])

    def test_invalid_paths_and_duplicate(self):
        for name in ('../file.txt', '/file.txt', './file.txt', 'a//b', 'file.txt', 'MANIFEST.sha256'):
            with self.subTest(name=name):
                self.manifest.write_text(f'{self.digest}  file.txt\n{self.digest}  {name}\n')
                with self.assertRaises(ValueError):
                    audit(self.root)

    def test_symlink(self):
        (self.root / 'file.txt').unlink()
        (self.root / 'file.txt').symlink_to('/etc/passwd')
        with self.assertRaises(ValueError):
            audit(self.root)

    def test_empty_and_malformed(self):
        for contents in ('', 'bad digest  file.txt\n'):
            self.manifest.write_text(contents)
            with self.assertRaises(ValueError):
                audit(self.root)
