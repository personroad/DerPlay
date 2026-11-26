"""Protect Build 3 runtime implementation; deliberate changes require user-approved baseline refresh."""
import hashlib, json, pathlib, unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCK = ROOT / 'DerPlay/build3-runtime-lock.json'
class FrozenBaselineTests(unittest.TestCase):
    def test_runtime_files_unchanged(self):
        lock = json.loads(LOCK.read_text())
        files = lock['files']
        exceptions = lock.get('approved_exceptions', {})
        self.assertEqual(set(exceptions), {'App/AppDelegate.swift', 'App/AppReleaseService.swift', 'App/AppReleaseViews.swift', 'App/CarScreenStore.swift', 'App/MediaSockets.swift', 'App/CarPlayMediaSession.swift', 'App/NativeReceiver.swift', 'App/CarLifeOutput.swift', 'App/BrowserReceiverPage.swift', 'App/LocalTLSIdentity.swift', 'App/ReceiverConfiguration.swift', 'App/SupportViews.swift', 'App/VideoOutputServer.swift', 'App/PxcConnection.swift', 'App/Localization/Localizable.xcstrings', 'App/CarPlayInfo.swift', 'App/Localization/Receiver.en.html', 'App/ReceiverViewController.swift', 'App/SettingsUI.swift', 'App/WiFiPresetStore.swift', 'Sources/TDSCarKitCore/PairSetup.swift'})
        for name, change in exceptions.items():
            self.assertEqual(files[name], change['original_sha256'])
        self.assertTrue(files)
        for name, digest in files.items():
            with self.subTest(path=name):
                path = ROOT / name
                self.assertTrue(path.is_file(), f'Missing frozen file: {name}')
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), exceptions.get(name, {}).get('approved_sha256', digest))
    def test_pending_protocols_not_enabled(self):
        api = (ROOT/'App/DerPlayExtensionAPI.swift').read_text()
        bridge = (ROOT/'App/DerPlayUpstreamBridge.swift').read_text()
        for id in ('derplay.easyconnection','derplay.iccoa.direct'):
            self.assertRegex(api, rf'id: "{id.replace(".", r"[.]")}"[^\n]*availability: \.development')
        self.assertIn('attributes: .disabled', bridge)
if __name__ == '__main__': unittest.main(verbosity=2)
