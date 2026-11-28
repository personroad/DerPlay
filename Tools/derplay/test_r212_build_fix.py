import unittest, json
import candidate_lock as guard

class R212BuildFixTests(unittest.TestCase):
    def test_navigation_cleanup_cast(self):
        text = (guard.ROOT / "App/ReceiverViewController.swift").read_text()
        body = text.split("private func finishConnectionLayer()", 1)[1].split("private func closeGlassSettings()", 1)[0]
        self.assertIn("(navigation as? DerPlayGlassNavigationController)?.onPlaybackSlotChanged = nil", body)
        self.assertIn("navigation.removeFromParent()", body)
        self.assertIn("settingsDismissed()", body)

    def test_immediate_parent_and_scope(self):
        path = guard.ROOT / "DerPlay/R211-candidate-lock.json"
        parent = json.loads(path.read_text())
        lock = json.loads((guard.ROOT / "DerPlay/R212-candidate-lock.json").read_text())
        self.assertEqual(guard.digest(path.read_bytes()), lock["immediate_parent_lock_sha256"])
        self.assertEqual(parent["methods"], lock["methods"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        self.assertEqual({n for n in parent["files"] if parent["files"][n] != lock["files"][n]}, {"App/ReceiverViewController.swift"})
        self.assertEqual(parent["files"]["App/ReceiverViewController.swift"]["candidate_sha256"], lock["files"]["App/ReceiverViewController.swift"]["r211_sha256"])
