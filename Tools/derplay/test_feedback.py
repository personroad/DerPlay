"""Guard the user-approved removal of the feedback feature."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
class FeedbackRemovalTests(unittest.TestCase):
    def test_no_route(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        for term in ['反馈与建议','DerPlayFeedbackViewController','v.wjx.cn']:
            self.assertNotIn(term,s)
    def test_no_private_resource(self):
        self.assertFalse((ROOT/'App/DerPlayFeedbackViewController.swift').exists())
        self.assertFalse((ROOT/'App/Assets.xcassets/DerPlayFeedbackQR.imageset').exists())
        self.assertNotIn('DerPlayFeedbackViewController',(ROOT/'TDSCarKit.xcodeproj/project.pbxproj').read_text())
if __name__=='__main__': unittest.main(verbosity=2)
