#!/usr/bin/env python3
"""Offline integration test of the sync helper using temporary Git repositories."""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).with_name('upstream.py')


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True, stderr=subprocess.STDOUT).strip()


class SyncTest(unittest.TestCase):
    def test_history_and_conflicts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            upstream, local = root / 'upstream', root / 'local'
            for repo in (upstream, local):
                repo.mkdir()
                git(repo, 'init', '-b', 'main')
                git(repo, 'config', 'user.email', 'test@example.invalid')
                git(repo, 'config', 'user.name', 'Test')
            (upstream / 'core.txt').write_text('original\n')
            (upstream / 'ui.txt').write_text('original UI\n')
            git(upstream, 'add', '.')
            git(upstream, 'commit', '-m', 'baseline')
            baseline = git(upstream, 'rev-parse', 'HEAD')
            (local / 'core.txt').write_text('original\n')
            (local / 'ui.txt').write_text('DerPlay UI\n')
            (local / 'DerPlay').mkdir()
            (local / 'Tools/derplay').mkdir(parents=True)
            shutil.copy2(SCRIPT, local / 'Tools/derplay/upstream.py')
            (local / 'DerPlay/upstream.json').write_text(json.dumps({'url': str(upstream), 'branch': 'main', 'initial_commit': baseline}))
            git(local, 'add', '.')
            git(local, 'commit', '-m', 'ZIP import')
            def run(*args, expected=0):
                p = subprocess.run([sys.executable, str(local / 'Tools/derplay/upstream.py'), *args], capture_output=True, text=True)
                self.assertEqual(p.returncode, expected, p.stdout + p.stderr)
                return p.stdout
            tree = git(local, 'rev-parse', 'HEAD^{tree}')
            self.assertIn('History linked: False', run('check'))
            run('prepare', '--branch', 'sync/unlinked', expected=1)
            run('bootstrap', '--branch', 'sync/base', expected=1)
            run('bootstrap', '--branch', 'sync/base', '--confirm-zip-baseline')
            self.assertEqual(tree, git(local, 'rev-parse', 'HEAD^{tree}'))
            self.assertEqual(baseline, git(local, 'rev-parse', 'HEAD^2'))
            git(local, 'switch', 'main')
            git(local, 'merge', '--ff-only', 'sync/base')
            self.assertIn('Already up to date', run('prepare', '--branch', 'sync/no-update'))
            (upstream / 'core.txt').write_text('updated core\n')
            git(upstream, 'commit', '-am', 'core update')
            self.assertIn('New upstream commits: 1', run('check'))
            run('prepare', '--branch', 'sync/update')
            self.assertEqual((local / 'core.txt').read_text(), 'updated core\n')
            self.assertEqual((local / 'ui.txt').read_text(), 'DerPlay UI\n')
            git(local, 'switch', 'main')
            git(local, 'merge', '--ff-only', 'sync/update')
            self.assertIn('New upstream commits: 0', run('check'))
            (upstream / 'ui.txt').write_text('upstream new UI\n')
            git(upstream, 'commit', '-am', 'UI update')
            main_before = git(local, 'rev-parse', 'main')
            self.assertIn('ui.txt', run('prepare', '--branch', 'sync/conflict', expected=2))
            self.assertEqual(git(local, 'rev-parse', 'main'), main_before)
            self.assertIn('UU ui.txt', git(local, 'status', '--short'))
            git(local, 'merge', '--abort')
            git(local, 'switch', 'main')
            (local / 'ui.txt').write_text('dirty\n')
            run('prepare', '--branch', 'sync/dirty', expected=1)
            self.assertEqual(git(local, 'branch', '--show-current'), 'main')


if __name__ == '__main__':
    unittest.main(verbosity=2)
