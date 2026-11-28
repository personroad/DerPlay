"""Candidate integrity: historical baseline and non-UI guards remain intact."""
import unittest, json, tempfile
from pathlib import Path
from unittest.mock import patch
import candidate_lock as guard

class R210LockLineageTests(unittest.TestCase):
    def test_parent_lock_and_exact_change_scope(self):
        path = guard.ROOT / 'DerPlay/R208-candidate-lock.json'
        parent = json.loads(path.read_text())
        lock = json.loads((guard.ROOT / "DerPlay/R210-candidate-lock.json").read_text())
        self.assertEqual(guard.digest(path.read_bytes()), lock['parent_lock_sha256'])
        self.assertEqual(parent['historical_lock_sha256'], lock['historical_lock_sha256'])
        self.assertEqual(parent['methods'], lock['methods'])
        self.assertEqual(set(parent['files']), set(lock['files']))
        changed = {name for name, entry in parent['files'].items() if entry != lock['files'][name]}
        self.assertEqual(changed, {'App/ReceiverViewController.swift', 'App/DerPlayGlassUI.swift'})
        for name in changed:
            self.assertEqual(parent['files'][name]['candidate_sha256'], lock['files'][name]['r208_sha256'])
            self.assertEqual(parent['files'][name]['r157_sha256'], lock['files'][name]['r157_sha256'])

    def test_modified_ui_candidate_is_rejected(self):
        for name in ('App/ReceiverViewController.swift', 'App/DerPlayGlassUI.swift'):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as d:
                dest = Path(d) / name
                dest.parent.mkdir(parents=True)
                dest.write_bytes((guard.ROOT / name).read_bytes() + b'\n// unexpected change\n')
                with patch.object(guard, 'ROOT', Path(d)):
                    with self.assertRaises(AssertionError):
                        guard.check_file(self, name, guard.LOCK['files'][name]['r157_sha256'])
