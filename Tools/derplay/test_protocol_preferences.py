import unittest
from pathlib import Path
from test_glass_ui import method
ROOT = Path(__file__).resolve().parents[2]
C = (ROOT/'App/ReceiverViewController.swift').read_text()
class ProtocolPreferencesTests(unittest.TestCase):
    def test_transition_before_save_and_guard(self):
        body = method(C,'headUnitOutputChanged')
        self.assertLess(body.index('guard !running, !waitingForNetwork'),body.index('restoreProtocolPreferences()'))
        self.assertLess(body.index('restoreProtocolPreferences()'),body.index('saveHeadUnitOutput()'))
        route = method(C,'interconnectRows')
        self.assertLess(route.index('self.headUnitOutputChanged()'),route.index('self.videoOutputToggled()'))
        self.assertIn('preferenceScope = currentPreferenceScope',method(C,'configureSettingsControls'))
    def test_scope_and_exclusions(self):
        store = (ROOT/'App/DerPlayProtocolPreferences.swift').read_text()
        for key in ('wifiSSID','wifiChannel','backgroundKeepAlive','pictureInPictureTiming','customVehicleButtonPNG'):
            self.assertNotIn('"'+key+'"',store)
        self.assertIn('old != new',store)
        self.assertIn('defaults.removeObject(forKey: name)',store)
        self.assertIn('ProtocolPreferencesSmoke.swift',(ROOT/'.github/workflows/build-ipa.yml').read_text())

    def test_recovery_before_control_restore(self):
        body = method(C,'configureSettingsControls')
        self.assertLess(body.index('recoverPendingTransition()'),body.index('driveControl.selectedSegmentIndex'))
        store = (ROOT/'App/DerPlayProtocolPreferences.swift').read_text()
        self.assertIn('forKey: Self.pendingKey',store)
        self.assertIn('defaults.removeObject(forKey: Self.pendingKey)',store)

    def test_shared_instrument_projection(self):
        body = method(C,'restoreProtocolPreferences')
        for field in ('ninebotAddressField.text', 'zeehoAddressField.text', 'zeeho62AutomaticSwitch.isOn', 'cfmotoAddressField.text'):
            self.assertGreater(body.index(field), body.index('.transition(from: previous, to: next)'))
        store = (ROOT/'App/DerPlayProtocolPreferences.swift').read_text()
        self.assertIn('Self.instrumentKeys(old)', store)
        self.assertIn('Self.instrumentKeys(new)', store)
        self.assertIn('instrumentIsolation', store)
