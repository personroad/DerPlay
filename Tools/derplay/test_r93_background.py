"""R93 source guards; not AVFoundation runtime tests."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
class R93Background(unittest.TestCase):
    def test_bounded_recovery_and_system_permission(self):
        s = (ROOT/'App/BackgroundKeepAlive.swift').read_text()
        for token in ['options.contains(.shouldResume)', 'recovery.beginInterruption()', 'player?.isPlaying == true', 'watchdog?.invalidate()', 'self.generation == token', 'recovery.claimRecovery(at: ProcessInfo.processInfo.systemUptime)', 'recovery.stop()']:
            self.assertIn(token,s)
        policy = (ROOT/'App/BackgroundRecoveryPolicy.swift').read_text()
        for token in ['attempts < 3', 'now - lastAttempt >= 15', 'guard isRunning, wasBackgrounded', 'state == .permitted']:
            self.assertIn(token,policy)
        self.assertIn('App/BackgroundRecoveryPolicy.swift',(ROOT/'TDSCarKit.xcodeproj/project.pbxproj').read_text())
        self.assertIn('Tools/derplay/BackgroundRecoverySmoke.swift',(ROOT/'.github/workflows/build-ipa.yml').read_text())
    def test_fixed_title_and_migration(self):
        s = (ROOT/'App/SettingsUI.swift').read_text()
        self.assertIn('note.topAnchor.constraint(equalTo: safe.topAnchor)',s)
        self.assertIn('pageSubtitle == nil ? 0 : 20',s)
        r = (ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('savedPiPTiming == 0 ? 1 : 0',r)
        self.assertIn('ChoiceMenu(items: [CWL("开启"), CWL("关闭")], fixedOrder: true)',r)
        self.assertIn('pictureInPictureTiming.selectedSegmentIndex == 0 ? 1 : 0',r)
        self.assertIn('pictureInPicture.setAutomatic(running && displayedVideo && pictureInPictureTiming.selectedSegmentIndex == 0)',r)
        self.assertIn('defaults.set(true, forKey: "backgroundKeepAlive")',r)
        self.assertNotIn('keepAliveSwitch',r)
        self.assertIn('pictureInPicture.stop(); keepAlive.stop()',r)
