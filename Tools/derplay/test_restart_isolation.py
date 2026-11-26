"""Source-level guards for delayed restart cancellation, not UIKit execution."""
import unittest
from test_glass_ui import CONTROLLER, method

class RestartIsolationTests(unittest.TestCase):
    def test_restart_ticket_is_single_use_and_checks_context(self):
        body = method(CONTROLLER, 'restartCarPlay')
        self.assertLess(body.index('stop()'), body.index('pendingAutomaticRestart = ticket'))
        self.assertLess(body.index('self.pendingAutomaticRestart == ticket'), body.index('self.cancelAutomaticRestart()'))
        for check in ('!self.waitingForNetwork', 'self.currentPreferenceScope == scope', 'self.localCarPlayAddress == restartAddress', 'UIApplication.shared.applicationState == .active', '!self.derPlayIdentityImporting'):
            self.assertLess(body.index(check), body.index('self.reportedScreen = keepScreen'))
        self.assertLess(body.index('self.cancelAutomaticRestart()'), body.index('self.toggleReceiver()'))
    def test_manual_actions_invalidate_ticket(self):
        for name in ('toggleReceiver', 'stop', 'revealSettings', 'restoreProtocolPreferences'):
            self.assertIn('cancelAutomaticRestart()', method(CONTROLLER, name))
        self.assertIn('pendingAutomaticRestart = nil', method(CONTROLLER, 'cancelAutomaticRestart'))
    def test_cancelled_network_wait_cannot_stop_new_session(self):
        body = method(CONTROLLER, 'waitForLocalNetwork')
        self.assertEqual(body.count('guard !Task.isCancelled, let self, self.waitingForNetwork else { return }'), 2)
        self.assertLess(body.rindex('guard !Task.isCancelled'), body.index('self.stop()'))
