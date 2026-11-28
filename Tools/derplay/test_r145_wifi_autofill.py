"""Static guards for add Wi-Fi autofill, not iOS entitlement/runtime tests."""
import unittest
from test_glass_ui import CONTROLLER, method
class DraftAutofillTests(unittest.TestCase):
    def test_current_network_permission_and_main_delivery(self):
        m=method(CONTROLLER,'detectDraftWiFiName')
        for token in ('locationManager.requestWhenInUseAuthorization()', 'NEHotspotNetwork.fetchCurrent', 'DispatchQueue.main.async', 'completion(nil)'):
            self.assertIn(token,m)
        self.assertIn('wifiDraftPermissionCompletion = nil',method(CONTROLLER,'locationManagerDidChangeAuthorization'))
    def test_credentials_read_on_serial_queue(self):
        m=method(CONTROLLER,'readDraftWiFiPassword')
        self.assertLess(m.index('wifiAddSaveQueue.async'),m.index('WiFiCredentials.password'))
        self.assertIn('DispatchQueue.main.async',m)
    def test_draft_only_and_edit_exit_guards(self):
        m=method(CONTROLLER,'addWiFiPage')
        for token in ('controller.onAppear = nil', 'draftActive, !draftTouched', 'name.text == ssid', 'guard draftEdited || (autoFilledCredentialSSID != nil && autoFilledCredentialSSID == name.text)', 'draftActive = false', 'self.wifiDraftPermissionCompletion = nil', 'password.text = saved', 'open.isOn = saved.isEmpty'):
            self.assertIn(token,m)
        self.assertLess(m.index('draftActive = false'),m.index('wifiAddSavePending = true'))
    def test_renamed_ssid_clears_old_autofilled_secret(self):
        m=method(CONTROLLER,'addWiFiPage')
        for token in ('name?.text != previous', 'autoFilledCredentialSSID = nil', 'password?.text = ""', 'open?.isOn = false', 'autoFilledCredentialSSID = ssid'):
            self.assertIn(token,m)
