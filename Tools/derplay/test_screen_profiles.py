"""Source guards for geometry profile integration, not a device handshake test."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
class ScreenProfilesTests(unittest.TestCase):
    def test_raw_geometry_before_first_reply(self):
        output=(ROOT/'App/CarLifeOutput.swift').read_text()
        select=output.split('session.selectDisplay =',1)[1].split('session.onDisplayNegotiated =',1)[0]
        self.assertIn('negotiation.raster == nil',select)
        self.assertIn('evidence: .screenGeometry(width, height)',select)
        self.assertIn('area: self.profileAreas[index]',select)
        self.assertIn('selectedRaw = (width, height, index)',select)
        self.assertIn('callback?(width, height, fps, selectedRaw?.width',output)
    def test_save_only_current_session_and_explicit_edit(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        branch=ui.split('receiver.prepareCarLife(configuration:',1)[1].split('self.startPreparedCarLife',1)[0]
        self.assertLess(branch.index('self.localStartupID == startupID'),branch.index('self.saveMatchedCarLifeLayout()'))
        self.assertIn('screenGeometry(rawWidth, rawHeight)',branch)
        self.assertIn('clearCarLifeProfileProjection()',ui.split('private func restoreProtocolPreferences()',1)[1].split('private func ',1)[0])
        self.assertIn('#selector(rememberCarLifeResolution)',ui)
        edit=ui.split('private func rememberCarLifeResolution()',1)[1].split('private func ',1)[0]
        self.assertIn('!running, !waitingForNetwork, outputMode == .carLife, followsCarScreen',edit)
        self.assertIn('lastCarLifeGeometry != nil',edit)
        save=ui.split('private func saveMatchedCarLifeLayout()',1)[1].split('private func ',1)[0]
        self.assertIn('let geometry = lastCarLifeGeometry',save)
        self.assertIn('old.replacingLayout',save)
    def test_matched_tier_does_not_overwrite_protocol_default(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('defaults.set(carLifeProfileDefaultIndex ?? resolutionControl.selectedSegmentIndex',ui)
        self.assertIn('self.carLifeProfileDefaultIndex = self.resolutionControl.selectedSegmentIndex',ui)
        self.assertIn('self.resolutionControl.selectedSegmentIndex = tier',ui)
        clear=ui.split('private func clearCarLifeProfileProjection()',1)[1].split('private func ',1)[0]
        self.assertIn('resolutionControl.selectedSegmentIndex = index',clear)
        self.assertIn('lastCarLifeGeometry = nil',clear)
        self.assertIn('carLifeProfileDefaultIndex = nil',clear)
    def test_icon_profile_before_native_start_and_default_isolation(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        branch=ui.split('receiver.prepareCarLife(configuration:',1)[1].split('self.startPreparedCarLife',1)[0]
        self.assertLess(branch.index('self.localStartupID == startupID'), branch.index('negotiated.widthPhysicalMM = DeviceProfilePolicy().iconWidthMM'))
        self.assertLess(branch.index('negotiated.widthPhysicalMM = DeviceProfilePolicy().iconWidthMM'), branch.index('try negotiated.validate()'))
        self.assertIn('$0.widthMM == negotiated.widthPhysicalMM', branch)
        self.assertIn('self.saveMatchedCarLifeLayout()', branch)
        self.assertIn('carLifeProfileDefaultIconIndex ?? iconSizeControl.selectedSegmentIndex', ui)
        self.assertIn('iconSizeControl.addTarget(self, action: #selector(rememberCarLifeResolution)', ui)
        clear=ui.split('private func clearCarLifeProfileProjection()',1)[1].split('private func ',1)[0]
        self.assertIn('iconSizeControl.selectedSegmentIndex = index', clear)
        self.assertIn('carLifeProfileDefaultIconIndex = nil', clear)

    def test_browser_uses_protocol_preferences_not_screen_profiles(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        prefs=(ROOT/'App/DerPlayProtocolPreferences.swift').read_text()
        for obsolete in ('projectBrowserProfileForEditing', 'browserEditingGeometry', 'currentBrowserGeometry', '编辑浏览器默认参数'):
            self.assertNotIn(obsolete, ui)
        self.assertIn('"derplay.dockPosition"', prefs)
        self.assertIn('config.dockPosition = DerPlayDockPosition.saved()', ui)
        target=ui.split('private var targetScreen: CarScreen?',1)[1].split('private func ',1)[0]
        self.assertIn('outputMode == .browser ? reportedScreen : nil', target)
        self.assertNotIn('CarScreenStore.preferred()',target)
        policy=(ROOT/'DerPlay/Extensions/DeviceProfilePolicy.swift').read_text()
        self.assertNotIn('scope == "browser" ||',policy)
        self.assertIn('entries.filter { $0.key.scope != "browser" }',policy)

    def test_layout_profile_applied_without_mutating_protocol_defaults(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        branch=ui.split('receiver.prepareCarLife(configuration:',1)[1].split('self.startPreparedCarLife',1)[0]
        for token in ('negotiated.rightHandDrive = savedLayout?.rightHandDrive', 'negotiated.dockPosition =', 'self.applyAppearance()'):
            self.assertIn(token,branch)
        self.assertLess(branch.index('negotiated.dockPosition ='), branch.index('try negotiated.validate()'))
        self.assertLess(branch.index('self.localStartupID == startupID'), branch.index('let savedLayout ='))
        clear=ui.split('private func clearCarLifeProfileProjection()',1)[1].split('private func ',1)[0]
        for token in ('driveControl.selectedSegmentIndex = index', 'carLifeProfileDock = nil', 'applyAppearance()'):
            self.assertIn(token,clear)
        for method, token in [('driveChanged','carLifeProfileDefaultDrive != nil'), ('dockPositionPage','self.carLifeProfileDock != nil')]:
            body=ui.split('func '+method+'()',1)[1].split('private func ',1)[0]
            self.assertIn(token,body)
            self.assertIn('saveMatchedCarLifeLayout()',body)
        self.assertIn('carLifeProfileDock ?? DerPlayDockPosition.saved()',ui)

    def test_vehicle_button_and_sound_preference_isolation(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        branch=ui.split('receiver.prepareCarLife(configuration:',1)[1].split('self.startPreparedCarLife',1)[0]
        for token in ('savedLayout?.carButton ?? self.carButtonSwitch.isOn', 'negotiated.oemIconPNG = nil', 'negotiated.oemIconPNG = self.customVehicleIcon ?? self.defaultVehicleIcon(appearanceIndex: savedLayout?.appearance)'):
            self.assertLess(branch.index(token), branch.index('try negotiated.validate()'))
        self.assertNotIn('selectedSoundOutput', branch)
        self.assertIn('self.carButtonSwitch.isOn = showVehicleButton', branch)
        self.assertIn('carLifeProfileDefaultCarButton ?? carButtonSwitch.isOn', ui)
        self.assertNotIn('carLifeProfileDefaultSound', ui)
        self.assertIn('carButtonSwitch.addTarget(self, action: #selector(rememberCarLifeResolution)', ui)
        self.assertIn('carButton: carButtonSwitch.isOn', ui)
        self.assertNotIn('negotiated.audioEnabled =',branch)
        clear=ui.split('private func clearCarLifeProfileProjection()',1)[1].split('private func ',1)[0]
        for token in ('carButtonSwitch.isOn = enabled', 'carLifeProfileDefaultCarButton = nil'):
            self.assertIn(token,clear)

    def test_picture_ratio_profile_isolated_and_selected_before_encoder_reply(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        output=(ROOT/'App/CarLifeOutput.swift').read_text()
        select=output.split('session.selectDisplay =',1)[1].split('session.onDisplayNegotiated =',1)[0]
        self.assertLess(select.index('negotiation.raster == nil'),select.index('fixedProfileSize'))
        self.assertLess(select.index('fixedProfileSize'),select.index('return fixed'))
        self.assertLess(select.index('return fixed'),select.index('DerPlayCarLifeDisplay.size(width: width'))
        self.assertIn('evidence: .screenGeometry(width, height)',select)
        page=ui.split('private func pictureRatioMenu()',1)[1].split('fileprivate func ',1)[0]
        scoped=page.split('if self.outputMode == .carLife',1)[1].split('self.sizeModeControl.selectedSegmentIndex',1)[0]
        self.assertIn('previous.replacingPicture(index: index',scoped)
        self.assertIn('store.save(next, scope: self.currentPreferenceScope, evidence: geometry)',scoped)
        self.assertIn('return',scoped)
        self.assertNotIn('sizeModeControl',scoped)
        self.assertNotIn('aspectRatioControl',scoped)
        self.assertIn('if config.carLifeEnabled && followsCarScreen {',ui)
        self.assertIn('matchedCarLifePictureIndex ?? (followsCarScreen',ui)
        self.assertIn('sizeMode: 0)',ui)

    def test_video_preferences_are_projected_but_wire_limits_remain(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        branch=ui.split('receiver.prepareCarLife(configuration:',1)[1].split('self.startPreparedCarLife',1)[0]
        self.assertLess(branch.index('self.localStartupID == startupID'), branch.index('savedLayout?.videoPreference'))
        self.assertLess(branch.index('savedLayout?.videoPreference'), branch.index('self.saveMatchedCarLifeLayout()'))
        self.assertIn('negotiated.videoCodec = .h264',branch)
        self.assertNotIn('negotiated.maxFPS =',branch)
        self.assertIn('.replacingVideo(fps:',ui)
        self.assertIn('carLifeProfileDefaultFPSIndex ?? frameRateControl.selectedSegmentIndex',ui)
        self.assertIn('carLifeProfileDefaultCodecIndex ?? codecControl.selectedSegmentIndex',ui)
        self.assertIn('if outputMode != .browser { fps = min(fps, 30) }',ui)
        self.assertIn('if outputMode != .browser { codec = .h264 }',ui)
        clear=ui.split('private func clearCarLifeProfileProjection()',1)[1].split('private func ',1)[0]
        self.assertIn('carLifeProfileDefaultFPSIndex = nil',clear)
        self.assertIn('carLifeProfileDefaultCodecIndex = nil',clear)
        self.assertIn('frameRateControl.selectedSegmentIndex = index',clear)
        self.assertIn('codecControl.selectedSegmentIndex = index',clear)

    def test_audio_capability_does_not_restore_legacy_sound_preference(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertNotIn('selectedSoundOutput', ui)
        self.assertNotIn('savedLayout?.soundOutput', ui)
        self.assertIn('audioEnabled: supportsCarPlayAudio(outputPort: outputPort)', ui)
        self.assertIn('config.browserAudio = config.audioEnabled && config.videoOutputPort != nil && outputMode == .browser', ui)

    def test_invalid_snapshot_cannot_shadow_valid_history(self):
        policy=(ROOT/'DerPlay/Extensions/DeviceProfilePolicy.swift').read_text()
        self.assertIn('preference.validSnapshot else { return false }',policy)
        self.assertIn('Self.isValidStoredKey($0.key) && $0.preference.validSnapshot && seen.insert($0.key).inserted',policy)
        self.assertIn('resolutionIndex >= 0 && validAdditionalPreferences',policy)
