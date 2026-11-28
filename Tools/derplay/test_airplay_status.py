import pathlib, unittest, json
ROOT = pathlib.Path(__file__).resolve().parents[2]
class AirPlayStatusTests(unittest.TestCase):
    def test_external_playback_gate(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text().split('private func refreshAirPlayPlaybackStatus() {',1)[1].split('private func tailingOutputSections',1)[0]
        gate=s.split('guard player.isExternalPlaybackActive else {',1)[1].split('let now =',1)[0]
        for token in ('airPlayWaitingSince = nil','airPlayRetryButton.isHidden = true','请选择 AirPlay 设备','正在连接 AirPlay…','return'):
            self.assertIn(token,gate)
        self.assertLess(s.index('guard player.isExternalPlaybackActive'),s.index('let prolongedWait'))
    def test_localization(self):
        strings=json.loads((ROOT/'App/Localization/Localizable.xcstrings').read_text())['strings']
        for key in ('请选择 AirPlay 设备','正在连接 AirPlay…'):
            self.assertIn('en',strings[key]['localizations'])
            self.assertIn('zh-Hans',strings[key]['localizations'])

    def test_recovery_does_not_restart_source(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        retry=s.split('private func retryAirPlayTransport()',1)[1].split('private func startAirPlayTransport()',1)[0]
        self.assertNotIn('restartCarPlay',retry)
        self.assertIn('receiver.requestKeyFrame',retry)
        status=s.split('private func refreshAirPlayPlaybackStatus()',1)[1].split('private func tailingOutputSections',1)[0]
        self.assertNotIn('if sourceStale {',status)
        self.assertIn('airPlayRecoveryCount < 2',status)
        self.assertIn('now - $0 >= 15',status)
        self.assertIn('if prolongedWait || airPlayTimelineStalled, item.status != .failed',status)
        self.assertIn('player.timeControlStatus == .playing',status)
        self.assertNotIn('#if DEBUG',status)

    def test_clock_stall_gate(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        status=s.split('private func refreshAirPlayPlaybackStatus()',1)[1].split('private func tailingOutputSections',1)[0]
        for token in ('player.currentTime().seconds', 'position.isFinite', 'now - anchor.uptime >= 10', 'resetAirPlayProgress()', 'if airPlayTimelineStalled {', 'UIApplication.shared.applicationState == .active'):
            self.assertIn(token,status)
        self.assertLess(status.index('if airPlayTimelineStalled {\n            updateAirPlayStatus'),status.index('正在投放到'))

    def test_player_session_isolation(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        ready=s.split('receiver.onAirPlayReady =',1)[1].split('receiver.onVideoOutputState',1)[0]
        self.assertIn('!self.airPlayReady',ready)
        start=s.split('private func startAirPlayTransport()',1)[1].split('@objc private func airPlayAudioRouteChanged',1)[0]
        self.assertNotIn('if let existing',start)
        self.assertLess(start.index('airPlayPlayer = nil'),start.index('previous?.pause()'))
        self.assertLess(start.index('previous?.replaceCurrentItem(with: nil)'),start.index('let player = AVPlayer()'))
        self.assertEqual(start.count('self.airPlayPlayer === player'),3)
        helper=start.split('private func installAirPlayItem',1)[1]
        self.assertIn('player.replaceCurrentItem(with: item)',helper)
        self.assertNotIn('AVPlayer()',helper)
        self.assertIn('player.currentItem === item',helper)

    def test_live_forward_buffer_preference(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        start=s.split('private func startAirPlayTransport()',1)[1].split('@objc private func airPlayAudioRouteChanged',1)[0]
        self.assertIn('item.preferredForwardBufferDuration = 3',start)
        self.assertLess(start.index('item.preferredForwardBufferDuration'),start.index('player.replaceCurrentItem(with: item)'))
        self.assertNotIn('automaticallyWaitsToMinimizeStalling = false',start)
