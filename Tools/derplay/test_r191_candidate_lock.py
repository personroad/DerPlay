"""Check that the candidate overlay still rejects unreviewed modifications."""
import tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import candidate_lock as guard
from test_glass_ui import CONTROLLER, method

class CandidateLockTests(unittest.TestCase):
    def test_modified_frozen_candidate_is_rejected(self):
        name = 'App/CarPlayAudio.swift'
        entry = guard.LOCK['files'][name]
        original = (guard.ROOT / name).read_bytes()
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            dest = root / name
            dest.parent.mkdir(parents=True)
            dest.write_bytes(original + b'\n// unexpected modification\n')
            with patch.object(guard, 'ROOT', root):
                with self.assertRaises(AssertionError):
                    guard.check_file(self, name, entry['r157_sha256'])

    def test_wrong_historical_digest_is_rejected(self):
        with self.assertRaises(AssertionError):
            guard.check_file(self, 'App/CarPlayAudio.swift', '0' * 64)

    def test_modified_method_is_rejected(self):
        with self.assertRaises(AssertionError):
            guard.check_method(self, 'loadIdentity', CONTROLLER, lambda text, name: method(text, name) + '\n// changed')

    def test_removed_appearance_method_cannot_return(self):
        with self.assertRaises(AssertionError):
            guard.check_method(self, 'appearanceChanged', CONTROLLER + '\nfunc appearanceChanged() {}\n', method)
