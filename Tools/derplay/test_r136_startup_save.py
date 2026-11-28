"""Static startup continuation guards; not UIKit or Keychain execution."""
import hashlib, unittest
from candidate_lock import check_method
from test_glass_ui import CONTROLLER, method, R136_STARTUP_SHA256

class StartupSaveTests(unittest.TestCase):
    def test_three_startup_continuations(self):
        body=method(CONTROLLER,'toggleReceiver')
        self.assertEqual(body.count('saveSettings(config) { [self] in'),3)
        self.assertNotIn('guard saveSettings(config)',body)
    def test_queue_and_cancellation(self):
        body=method(CONTROLLER,'saveSettings')
        self.assertLess(body.index('wifiAddSaveQueue.async'),body.index('WiFiCredentials.save('))
        self.assertLess(body.index('DispatchQueue.main.async {'),body.index('guard self.startupWiFiTicket == ticket else'))
        self.assertLess(body.index('guard self.startupWiFiTicket == ticket else'),body.index('self.commitStartupSettings'))
        self.assertIn('startupWiFiTicket = nil',method(CONTROLLER,'stop'))
        self.assertIn('if startupWiFiTicket != nil { stop() }',method(CONTROLLER,'backgrounded'))
    def test_failure_and_slow_wait(self):
        body=method(CONTROLLER,'saveSettings')
        self.assertIn('.now() + 8',body)
        self.assertIn('self.wifiAddSavePending = false',body)
        self.assertNotIn('completion()',body.split('case .failure:',1)[1])
        self.assertIn('guard needsNetworkDetails else',body)
    def test_commit_hash_and_no_keychain(self):
        body=method(CONTROLLER,'commitStartupSettings')
        check_method(self, 'commitStartupSettings', CONTROLLER, method)
        self.assertNotIn('audioSettingChanged()',body)
        self.assertIn('pictureInPictureTiming.selectedSegmentIndex == 0 ? 1 : 0',body)
        self.assertNotIn('WiFiCredentials.save(',body)
