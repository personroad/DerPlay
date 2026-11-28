"""R95 runtime Wi-Fi recovery and foreground-only maintenance source guards."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
class R95NetworkPowerTests(unittest.TestCase):
    def test_runtime_recovery_requires_real_outage_and_stale_video(self):
        policy = (ROOT / "DerPlay/Extensions/NetworkRecoveryPolicy.swift").read_text()
        for token in ("outageDuration >= 3", "now - restoredAt", "videoAge >= 10", "attempts < 2", "appActive", "hasAddress"):
            self.assertIn(token, policy)
        controller = (ROOT / "App/ReceiverViewController.swift").read_text()
        for token in ("path.status == .satisfied", "receiver.lastVideoArrivalUptime", "outputMode.usesInstrumentWiFi", "runtimeNetworkRecovery.claimRecovery", "self.restartCarPlay(reason:", "UIApplication.shared.applicationState == .active"):
            self.assertIn(token, controller)
        receiver = (ROOT / "App/NativeReceiver.swift").read_text()
        self.assertIn("self.recordVideoArrival()", receiver)
        self.assertLess(receiver.index("self.recordVideoArrival()"), receiver.index("guard self.localVideoEnabled else { return }"))
        self.assertIn("videoArrivalUptime = nil", receiver)
        self.assertIn("runtimeNetworkRecovery.stop()", controller)
        self.assertIn("runtimeNetworkRecoveryWork?.cancel()", controller)
    def test_no_restart_on_path_flap_or_while_backgrounded(self):
        controller = (ROOT / "App/ReceiverViewController.swift").read_text()
        body = controller.split("private func scheduleRuntimeNetworkRecoveryCheck()", 1)[1].split("private func refreshNetworkAddresses()", 1)[0]
        self.assertIn("UIApplication.shared.applicationState == .active", body)
        self.assertIn("currentVideoAge >= 10", body)
        self.assertIn("self.networkRestartCount < 2", body)
        self.assertIn("self.autoRestarts < 2", body)
        self.assertIn("outputMode.usesInstrumentWiFi", controller)
    def test_periodic_maintenance_is_suspended_in_background(self):
        controller = (ROOT / "App/ReceiverViewController.swift").read_text()
        self.assertIn("private func startForegroundMaintenance()", controller)
        self.assertIn("private func pauseForegroundMaintenance()", controller)
        self.assertIn("updateTimer?.invalidate(); updateTimer = nil", controller)
        self.assertIn("airPlayHealthTimer?.invalidate(); airPlayHealthTimer = nil", controller)
        self.assertIn("pauseForegroundMaintenance()", controller.split("@objc private func backgrounded()", 1)[1])
        self.assertIn("startForegroundMaintenance()", controller.split("@objc private func becameActive()", 1)[1])
        self.assertIn("Timer(timeInterval: 2, repeats: true)", controller)
        self.assertIn("guard UIApplication.shared.applicationState == .active,", controller.split("private func refreshAirPlayPlaybackStatus()", 1)[1])
if __name__ == "__main__": unittest.main(verbosity=2)
