"""Protect Build 3 runtime implementation; deliberate changes require user-approved baseline refresh."""
import hashlib, json, pathlib, unittest
from candidate_lock import LOCK as CANDIDATE, FILES, check_file
ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCK = ROOT / 'DerPlay/build3-runtime-lock.json'
class FrozenBaselineTests(unittest.TestCase):
    def test_runtime_files_unchanged(self):
        lock = json.loads(LOCK.read_text())
        self.assertEqual(hashlib.sha256(LOCK.read_bytes()).hexdigest(), CANDIDATE['historical_lock_sha256'])
        self.assertEqual(set(CANDIDATE['files']), FILES)
        files = lock['files']
        exceptions = lock.get('approved_exceptions', {})
        self.assertEqual(set(exceptions), {'App/BackgroundKeepAlive.swift', 'App/FragmentedMP4.swift', 'App/AppDelegate.swift', 'App/AppReleaseService.swift', 'App/AppReleaseViews.swift', 'App/CarScreenStore.swift', 'App/MediaSockets.swift', 'App/CarPlayMediaSession.swift', 'App/NativeReceiver.swift', 'App/CarLifeOutput.swift', 'App/BrowserReceiverPage.swift', 'App/LocalTLSIdentity.swift', 'App/ReceiverConfiguration.swift', 'App/SupportViews.swift', 'App/VideoOutputServer.swift', 'App/PxcConnection.swift', 'App/Localization/Localizable.xcstrings', 'App/CarPlayInfo.swift', 'App/Localization/Receiver.en.html', 'App/ReceiverViewController.swift', 'App/SettingsUI.swift', 'App/WiFiPresetStore.swift', 'Sources/TDSCarKitCore/PairSetup.swift', 'DerPlay/Extensions/NetworkRecoveryPolicy.swift'})
        for name, change in exceptions.items():
            self.assertEqual(files[name], change['original_sha256'])
        self.assertTrue(files)
        for name, digest in files.items():
            with self.subTest(path=name):
                path = ROOT / name
                self.assertTrue(path.is_file(), f'Missing frozen file: {name}')
                historical = exceptions.get(name, {}).get('approved_sha256', digest)
                if name in FILES:
                    check_file(self, name, historical)
                else:
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), historical)
        # The navigation surface was not in the historical lock; pin it too.
        for name in FILES - files.keys():
            with self.subTest(path=name):
                self.assertEqual(hashlib.sha256((ROOT / name).read_bytes()).hexdigest(), CANDIDATE['files'][name]['candidate_sha256'])
    def test_pending_protocols_not_enabled(self):
        api = (ROOT/'App/DerPlayExtensionAPI.swift').read_text()
        bridge = (ROOT/'App/DerPlayUpstreamBridge.swift').read_text()
        for id in ('derplay.easyconnection','derplay.iccoa.direct'):
            self.assertRegex(api, rf'id: "{id.replace(".", r"[.]")}"[^\n]*availability: \.development')
        self.assertIn('attributes: .disabled', bridge)
if __name__ == '__main__': unittest.main(verbosity=2)
