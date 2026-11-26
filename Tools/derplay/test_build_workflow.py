"""Guard the manual, single-IPA workflow and runner selection."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class BuildWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.workflow = (ROOT / '.github/workflows/build-ipa.yml').read_text()

    def test_runner_allowlist_and_default(self):
        self.assertIn('default: macos-15\n', self.workflow)
        self.assertIn('type: choice', self.workflow)
        self.assertIn('runs-on: ${{ inputs.runner == \'macos-15-intel\' && \'macos-15-intel\' || \'macos-15\' }}', self.workflow)
        self.assertNotIn('macos-15-large', self.workflow)

    def test_branch_scoped_concurrency(self):
        self.assertIn('group: derplay-ipa-${{ github.ref }}', self.workflow)
        self.assertIn('cancel-in-progress: true', self.workflow)

    def test_manual_single_unsigned_ipa(self):
        self.assertIn('workflow_dispatch:', self.workflow)
        self.assertNotIn('\n  push:', self.workflow)
        self.assertEqual(self.workflow.count('name: DerPlay-IPA'), 1)
        self.assertIn('ARCHS=arm64', self.workflow)
        self.assertIn('CODE_SIGNING_ALLOWED=NO', self.workflow)
        self.assertIn('contents: read', self.workflow)

if __name__ == '__main__':
    unittest.main()
