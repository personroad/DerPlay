"""R96 guards for bounded foreground AirPlay HLS item recovery."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]

class R96AirPlayRecoveryTests(unittest.TestCase):
    def test_policy_is_conservative_and_bounded(self):
        policy = (ROOT / "DerPlay/Extensions/NetworkRecoveryPolicy.swift").read_text()
        for token in ("struct DerPlayAirPlayRecoveryPolicy", "attempts < 2", "now - lastAttempt < 20",
                      "appIsActive", "externalPlaybackIsActive", "sourceFramesAreFresh", "explicitlyPaused"):
            self.assertIn(token, policy)

    def test_reload_keeps_existing_player_and_selected_route(self):
        controller = (ROOT / "App/ReceiverViewController.swift").read_text()
        helper = controller.split("private func installAirPlayItem(", 1)[1].split("@objc private func airPlayAudioRouteChanged", 1)[0]
        self.assertIn("player.replaceCurrentItem(with: item)", helper)
        self.assertIn("airPlayPlayer === player", helper)
        self.assertNotIn("AVPlayer()", helper)
        self.assertNotIn("AVRoutePickerView", helper)
        self.assertIn("sourceFramesAreFresh", controller)
        self.assertIn("airPlayTransportRecovery.reset()", controller)

    def test_recovery_only_runs_foreground_and_does_not_override_user_pause(self):
        controller = (ROOT / "App/ReceiverViewController.swift").read_text()
        refresh = controller.split("private func refreshAirPlayPlaybackStatus()", 1)[1].split("private func updateAirPlay", 1)[0]
        self.assertIn("UIApplication.shared.applicationState == .active", refresh)
        self.assertIn("explicitlyPaused: item.status == .readyToPlay && player.timeControlStatus == .paused", refresh)
        self.assertIn("case .reloadCurrentItem(let attempt)", refresh)
        self.assertIn("case .exhausted", refresh)

    def test_foreground_resume_rechecks_existing_airplay_session(self):
        controller = (ROOT / "App/ReceiverViewController.swift").read_text()
        became_active = controller.split("@objc private func becameActive()", 1)[1].split("@objc private func pictureInPictureTimingChanged", 1)[0]
        self.assertIn("if running, outputMode == .airPlay { refreshAirPlayPlaybackStatus() }", became_active)

if __name__ == "__main__":
    unittest.main(verbosity=2)
