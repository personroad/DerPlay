"""Historical UI requirements; source checks, not rendered UIKit acceptance."""
import hashlib, json, re, unittest
from test_glass_ui import ROOT, CONTROLLER, GLASS, SETTINGS, method

class R192UIRestoration(unittest.TestCase):
    def test_colored_single_layer_navigation_button(self):
        for token in ['nativeButtonConfiguration(prominent: true)', '.capsule', 'DerPlayGlassPalette.stopRed : DerPlayGlassPalette.startGreen', 'baseForegroundColor = .white', 'pointSize: 24']:
            self.assertIn(token, CONTROLLER)
        self.assertIn('addSubview(button)', GLASS)
        self.assertIn('playbackContent.isUserInteractionEnabled = false', GLASS)
        self.assertIn('slot.hidesSharedBackground = true', method(GLASS, 'clearTrailingPlaybackControls'))
        self.assertNotIn('hidesSharedBackground', method(GLASS, 'glassButton'))

    def test_general_settings_pages_stay_button_free(self):
        close = method(GLASS, 'clearTrailingPlaybackControls')
        self.assertNotIn('glassButton(symbol: "xmark"', close)
        self.assertIn('page.navigationItem.rightBarButtonItems = items.isEmpty ? nil : items', close)
        self.assertIn('clearTrailingPlaybackControls(on: viewController)', GLASS)
        self.assertNotIn('private func installPlayback(', GLASS)

    def test_preview_shadow_is_consistent_in_both_states(self):
        helper = GLASS.split('static func previewShadow(',1)[1].split('static func styleAction',1)[0]
        self.assertIn('shadow(view, radius: 8, offset: 10)', helper)
        self.assertIn('view.layer.shadowOpacity = 0.22', helper)
        self.assertIn('DerPlayGlassPalette.previewShadow(inlineVideoShadow)', CONTROLLER)
        self.assertIn('DerPlayGlassPalette.previewShadow(derPlayPreviewPlaceholder)', CONTROLLER)
        self.assertNotIn('shadow(inlineVideoShadow, radius: 16', CONTROLLER)
        self.assertNotIn('shadow(derPlayPreviewPlaceholder, radius: 16', CONTROLLER)

    def test_playback_changes_rebuild_settings_on_main_queue(self):
        panel = method(CONTROLLER, 'refreshDerPlayPanel')
        self.assertIn('let playbackState = [running, waitingForNetwork, carLifeNegotiationTimeout != nil]', panel)
        self.assertIn('if lastSettingsPlaybackState != playbackState', panel)
        self.assertIn('scheduleSettingsPlaybackRefresh()', panel)
        self.assertIn('private var running = false { didSet { refreshDerPlayPanel() } }', CONTROLLER)
        self.assertIn('private var waitingForNetwork = false { didSet { refreshDerPlayPanel() } }', CONTROLLER)
        route = method(CONTROLLER, 'connectionPlaybackTapped')
        self.assertIn('toggleReceiver()', route)
        self.assertIn('scheduleSettingsPlaybackRefresh()', route)
        refresh = method(CONTROLLER, 'scheduleSettingsPlaybackRefresh')
        for token in ['!settingsPlaybackRefreshPending', 'DispatchQueue.main.async', 'self.settingsNavigation === navigation', 'page.isViewLoaded', 'self.reloadVisibleSettings()']:
            self.assertIn(token, refresh)
        self.assertIn('?.reload()', method(CONTROLLER, 'reloadVisibleSettings'))
        self.assertIn('guard !containsEditingField(tableView) else { reloadPending = true; return }', SETTINGS)
        self.assertIn('sections = build(); cells.removeAll()', SETTINGS)
        self.assertIn('if self.reloadPending { self.reload() }', SETTINGS)
        self.assertIn('let locked = running || waitingForNetwork', method(CONTROLLER, 'interconnectRows'))

    def test_nav_playback_respects_certificate_availability(self):
        panel = method(CONTROLLER, 'refreshDerPlayPanel')
        self.assertIn('startButton.isEnabled = active || !derPlayIdentityImporting', panel)
        self.assertIn('ConnectionControlLayer(button: startButton, homeSlot: playbackHomeSlot)', CONTROLLER)
        self.assertIn('addSubview(button)', GLASS)
        self.assertIn('refreshDerPlayPanel()', method(CONTROLLER, 'importDerPlayIdentity'))

    def test_fixed_pip_order_without_changing_saved_values(self):
        self.assertIn('pictureInPictureTiming = ChoiceMenu(items: [CWL("开启"), CWL("关闭")], fixedOrder: true)', CONTROLLER)
        self.assertIn('init(items: [String], fixedOrder: Bool = false)', SETTINGS)
        self.assertIn('if fixedOrder { button.preferredMenuElementOrder = .fixed }', SETTINGS)
        self.assertIn('state: index == selectedSegmentIndex ? .on : .off', SETTINGS)
        self.assertIn('savedPiPTiming == 0 ? 1 : 0', CONTROLLER)
        self.assertIn('pictureInPictureTiming.selectedSegmentIndex == 0 ? 1 : 0', CONTROLLER)
        self.assertIn('pictureInPicture.setAutomatic(running && displayedVideo && pictureInPictureTiming.selectedSegmentIndex == 0)', CONTROLLER)

    def test_home_certificate_entry_not_hidden_by_other_status(self):
        panel = method(CONTROLLER, 'refreshDashboardStatus')
        self.assertIn('let certificatePrompt = CWL("需要导入 MFi 证书")', panel)
        self.assertIn('if needsCertificate && !lines.contains(certificatePrompt) { lines.append(certificatePrompt) }', panel)
        self.assertIn('if !needsCertificate { lines.removeAll { $0 == certificatePrompt } }', panel)
        self.assertIn('Button(action: importCertificate)', GLASS)
        self.assertIn('self?.revealSettings(certificate: true)', CONTROLLER)
        self.assertIn('if certificate { navigation.pushViewController(derPlayIdentityPage(), animated: false) }', CONTROLLER)

    def test_certificate_ui_labels_and_validation_not_removed(self):
        page = method(CONTROLLER, 'derPlayIdentityPage')
        error = method(CONTROLLER, 'certificateImportErrorMessage')
        for body in [page, error, method(CONTROLLER, 'importDerPlayIdentity')]:
            self.assertNotIn('身份', body)
        for label in ['MFi 证书管理','证书状态','导入 MFi 证书','重新检测证书','清除已导入证书','证书检测','清除证书？']:
            self.assertIn('CWL("'+label+'")', page)
        self.assertNotIn('.info(CWL("身份格式")', page)
        self.assertNotIn('.info(CWL("证书与私钥匹配")', page)
        self.assertIn('try AccessoryIdentityStore.clearIdentity()', page)
        self.assertIn('try AccessoryIdentityStore.importMaterial(result.get())', CONTROLLER)
        self.assertIn('try DerPlayIdentityImport.recognize(data)', CONTROLLER)
        for case in ['selection','missingChain','missingKey','missingLeaf','file','format','mismatch','ambiguous','keychain']:
            self.assertIn('case .'+case, error)

    def test_touched_ui_has_bilingual_catalog_entries(self):
        catalog=json.loads((ROOT/'App/Localization/Localizable.xcstrings').read_text())['strings']
        for body in [method(CONTROLLER,'derPlayIdentityPage'),method(CONTROLLER,'certificateImportErrorMessage'),method(CONTROLLER,'importDerPlayIdentity'),method(GLASS,'updateButtonAppearance'),method(CONTROLLER,'refreshDerPlayPanel')]:
            for key in re.findall(r'CWL\("([^"\n]+)"',body):
                with self.subTest(key=key):
                    self.assertIn(key, catalog)
                    self.assertTrue(catalog[key]['localizations']['en']['stringUnit']['value'])

    def test_original_and_r191_locks_retained(self):
        lock=json.loads((ROOT/'DerPlay/R192-candidate-lock.json').read_text())
        old=(ROOT/'DerPlay/R191-candidate-lock.json').read_bytes()
        self.assertEqual(hashlib.sha256(old).hexdigest(),lock['previous_lock_sha256'])
        previous=json.loads(old)
        for name,entry in previous['files'].items():
            updated=lock['files'][name]
            self.assertEqual(entry['r157_sha256'],updated['r157_sha256'])
            if name in {'App/ReceiverViewController.swift','App/DerPlayGlassUI.swift','App/Localization/Localizable.xcstrings'}:
                self.assertEqual(entry['candidate_sha256'],updated['r191_sha256'])
            else:
                self.assertEqual(entry['candidate_sha256'],updated['candidate_sha256'])

if __name__=='__main__': unittest.main(verbosity=2)
