"""Static source regression checks; no UIKit runtime simulation."""
import unittest
from pathlib import Path
S=(Path(__file__).resolve().parents[2]/'App/ReceiverViewController.swift').read_text()
F=S.split('private func wifiForm()',1)[1].split('private func addWiFiPage()',1)[0]
class WiFiNavigationTests(unittest.TestCase):
    def test_temporary_disappearance_precedes_commit(self):
        self.assertLess(F.index('navigation.viewControllers.contains'),F.index('self.activeWiFiForm = nil'))
        self.assertLess(F.index('!navigation.isBeingDismissed'),F.index('self.wifiAddSavePending = true'))
    def test_actual_exit_and_weak_capture(self):
        self.assertIn('controller.onLeave = { [weak self, weak controller]',F)
        self.assertIn('self.activeWiFiForm == form',F)
        self.assertIn('!self.wifiAddSavePending',F)
        self.assertIn('self.wifiAddSavePending = true',F)
