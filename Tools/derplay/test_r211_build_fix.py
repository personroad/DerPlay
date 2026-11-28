import unittest, json
import candidate_lock as guard

class R211BuildFixTests(unittest.TestCase):
    def test_uiview_gesture_override(self):
        text = (guard.ROOT / "App/DerPlayGlassUI.swift").read_text().split("final class ConnectionControlLayer:", 1)[1]
        self.assertIn("override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool", text)

    def test_immediate_parent_and_scope(self):
        lock = json.loads((guard.ROOT / "DerPlay/R211-candidate-lock.json").read_text())
        path = guard.ROOT / "DerPlay/R210-candidate-lock.json"
        parent = json.loads(path.read_text())
        self.assertEqual(guard.digest(path.read_bytes()), lock["immediate_parent_lock_sha256"])
        self.assertEqual(parent["methods"], lock["methods"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        self.assertEqual({n for n in parent["files"] if parent["files"][n] != lock["files"][n]}, {"App/DerPlayGlassUI.swift"})
        self.assertEqual(parent["files"]["App/DerPlayGlassUI.swift"]["candidate_sha256"], lock["files"]["App/DerPlayGlassUI.swift"]["r210_sha256"])
