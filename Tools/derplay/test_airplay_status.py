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
