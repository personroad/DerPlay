import pathlib, plistlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
class WiFiJoinTests(unittest.TestCase):
    def test_explicit_join_only(self):
        s=(ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertEqual(s.count('joinConfiguredWiFi()'),2)
        self.assertIn('configuration.joinOnce = true',s)
        self.assertIn('guard !wifiJoinPending else',s)
        self.assertIn('self.activeWiFiForm == form',s)
        self.assertIn('NEHotspotConfigurationManager.shared.apply(configuration)',s)
    def test_opt_in_entitlement(self):
        key='com.apple.developer.networking.HotspotConfiguration'
        self.assertNotIn(key,plistlib.loads((ROOT/'App/TDSCarKit.entitlements').read_bytes()))
        self.assertTrue(plistlib.loads((ROOT/'App/TDSCarKit-Hotspot.entitlements').read_bytes())[key])
