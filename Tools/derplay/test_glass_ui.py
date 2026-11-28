"""Presentation-only UI source guards; not Xcode/UI automation tests."""
import hashlib,re,unittest
from candidate_lock import LOCK as CANDIDATE, METHODS, check_method
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
CONTROLLER=(ROOT/'App/ReceiverViewController.swift').read_text()
GLASS=(ROOT/'App/DerPlayGlassUI.swift').read_text()
SETTINGS=(ROOT/'App/SettingsUI.swift').read_text()
def method(text,name):
 m=re.search(r'^    (?:@objc )?(?:(?:private|fileprivate|override) )?func '+re.escape(name)+r'\(',text,re.M); assert m,name
 end=re.search(r'^    (?:(?:@objc )?(?:(?:private|fileprivate|override) )?(?:func|var|let|static|struct|enum)\b|// MARK:)|^}',text[m.end():],re.M)
 return text[m.start():m.end()+(end.start() if end else len(text)-m.end())].rstrip()

RUNTIME_METHOD_SHA256 = {'toggleReceiver': '780ae8ff2813543f5b5a343510ca03c1b6f880a4265460aef91c88e0cb2e6d7c', 'startPreparedCarLife': 'ca89a4efa201d33faae8fc1fe2043fcee4cb0cbdbbb8e02623236031e70ab079', 'stop': 'dfd61e0b31bf747caf3db3b6ec0198068e467cee587b1b608770049bdd242302', 'setEditing': '5b8a1c3a47e1efa2d23989f0832289d3958485b4779f3b6568794c6c03366a34', 'configureDisplay': '39a2d7da485b3c28a61ee042e83dd78a822b137071354194b291bbfade94bc04', 'planDisplay': '1fcec4106ce9f46900ac9562e2b015ac0a423a319ab97044b56f485bfb9cf0b8', 'saveSettings': 'bcf7e7aeb8ddecdd91dd4e542c9a1637ec0ddfa3f26f3083eeb5f0ca2c92df09', 'saveHeadUnitOutput': 'bff12f4c9896b600b4775a8d4a381a9421e64a5c2261e9f36dd5ce15c983e7b6', 'headUnitOutputChanged': '9c1c82777b555b4f58d2a7db21817947ee81fc5d89b2b1b789c50dca1b879824', 'videoOutputToggled': 'da2c8bd8eb963c1f6190065ba6531db6eafcaa1882315f6409ba0c031d017983', 'appearanceChanged': '04cf4ca3dcf163f276aed59dd96e4b18be516eb56d38f4e6835de2705d8f40b5', 'showFullscreen': '684d2ccc82162b5aea7388d17bb2136b91d0f8bd0926cfe5774075d7375e0fd9', 'hideFullscreen': 'c57af16f820ca4368d14b771deb13d0a3d36c926464ea3c04e29b216f10c0019', 'startPictureInPicture': '8585b4642f65754374292286905c8c02a6fabd9baab9319db8898acb6eb3d122', 'restoreInlineVideoSurface': 'e75284f630941f4915272fd35f0cb663583382538a65c959bd9019c29870bd79', 'updatePictureInPicturePolicy': '828530081d756e9fa2346ba6cf0e3187d5d552c80ca903063079fec0b022e46b', 'restartCarPlay': '4c96ca53eb10c5ea1364ddebab8f3ea275fd92f62c1732e3334f8ed1e7163347', 'configureSettingsControls': 'f178cdfb6cb0a3ce3d56c1850d0185303113ca5dd8a3ffed77d24283a3f40d0c', 'saveCurrentWiFiPreset': 'ea9d83bc4ec9dae0aa5da76ea1669638dfeff4a3e2abe17bffd12f292747f19e', 'derPlayIdentityPage': 'd43ae9c4778f4ae182413788b780c58327ad27442bc43e8e0fcdf152cc967e82', 'documentPickerWasCancelled': '60d1174d038c3c0ecbf67da4aa95d7204c293ec44d40340e9336029bf4097b97', 'loadIdentity': '61f701d44dc70709513e014aeded9707b87030b18845c4afe6933c43a4131d36'}

R136_STARTUP_SHA256 = {'saveSettings': '7fb054bcccf498ebd4fc103e6acb3187f750afb194e9ff84f70d48b230b2553a', 'commitStartupSettings': '0068dd04cd2cf2acf5be4a08e8a03d35ad84975a0718ec20376ea8d285685764'}

class GlassUITests(unittest.TestCase):
    def test_home_airplay_row_is_clickable_and_adapts_to_appearance(self):
        self.assertIn('Button(action: openAirPlayPicker)', GLASS)
        self.assertIn('private func openAirPlayPicker()', GLASS)
        self.assertIn('airPlayPicker.firstSubview(of: UIButton.self)?.sendActions(for: .touchUpInside)', GLASS)
        self.assertIn('foregroundStyle(scheme == .dark ? Color.white : Color.black)', GLASS)
        self.assertIn('DerPlayHomeAirPlayPicker(picker: airPlayPicker)', GLASS)
        self.assertNotIn('glassEffect(.regular, in: Circle())', GLASS.split('if state.showsAirPlayPicker {', 1)[1].split('}', 1)[0])

    def test_home_card_order_and_real_routes(self):
        labels=['menuRow(CWL("通用设置")','menuRow(CWL("连接模式")']
        self.assertEqual(sorted(GLASS.index(x) for x in labels),[GLASS.index(x) for x in labels])
        for route in ['self?.revealSettings()','self?.revealSettings(output: true)']:
            self.assertIn(route,CONTROLLER)
        self.assertIn('navigationItem.rightBarButtonItem = nil',CONTROLLER)
        self.assertIn('dashboardHost.didMove(toParent: self)',CONTROLLER)
    def test_native_glass_and_fallback(self):
        for token in ['#if compiler(>=6.2)','#available(iOS 26.0, macCatalyst 26.0, *)','rows.glassEffect','rows.background(.ultraThinMaterial','accessibilityReduceTransparency']:
            self.assertIn(token,GLASS)
    def test_single_settings_sheet_and_playback_control(self):
        route=method(CONTROLLER,'revealSettings')
        for token in ['DerPlayGlassNavigationController(rootViewController: rootSettingsPage())','modalPresentationStyle = .pageSheet','sheet.detents = [.custom','preferredCornerRadius = 34','navigation.onClose','present(navigation, animated: true)','prepareConnectionLayer()']:
            self.assertIn(token,route)
        self.assertIn('navigationController?.pushViewController(make(), animated: true)',SETTINGS)
        self.assertIn('clearTrailingPlaybackControls(on: viewController)',GLASS)
        self.assertIn('navigation.reservesConnectionPlayback = true',method(CONTROLLER,'prepareConnectionLayer'))
        self.assertIn('connectionControlLayer?.active = active',CONTROLLER)
        self.assertIn('navigation.dismiss(animated: true)',method(CONTROLLER,'closeGlassSettings'))
        self.assertIn('settingsNavigation = nil',method(CONTROLLER,'settingsDismissed'))

    def test_settings_sheet_continuous_material_and_safe_header(self):
        for token in ['view.backgroundColor = DerPlayGlassPalette.sheetTint', 'appearance.configureWithOpaqueBackground()', 'navigationBar.isTranslucent = true', 'navigationBar.compactScrollEdgeAppearance = appearance', 'page.navigationItem.compactScrollEdgeAppearance = appearance']:
            self.assertIn(token, GLASS)
        self.assertNotIn('view.insertSubview(backdrop, at: 0)', GLASS)
        self.assertNotIn('appearance.backgroundEffect = UIBlurEffect', GLASS)
        self.assertIn('tableView.backgroundView = nil', SETTINGS)
        self.assertIn('tableView.contentInsetAdjustmentBehavior = .automatic', SETTINGS)
        self.assertIn('extendedLayoutIncludesOpaqueBars = false', SETTINGS)
        self.assertIn('tableView.clipsToBounds = true', SETTINGS)

    def test_r45_opaque_animated_navigation(self):
        self.assertIn('super.pushViewController(viewController, animated: animated)', GLASS)
        self.assertIn('interactivePopGestureRecognizer?.isEnabled = viewControllers.count > 1', GLASS)
        self.assertIn('page.view.backgroundColor = DerPlayGlassPalette.sheetTint', GLASS)
        self.assertIn('tableView.backgroundColor = DerPlayGlassPalette.sheetTint', SETTINGS)
        self.assertNotIn('alpha: 0.72', GLASS)
        self.assertNotIn('super.popViewController(animated: false)', GLASS)
    def test_r42_settings_palette(self):
        root = method(CONTROLLER, 'rootSettingsPage')
        for token in ['"moon.stars.fill", .systemBlue', '"pip.fill", .systemPurple', '"lock.shield", .systemGreen', '"info.circle.fill", .systemGray']:
            self.assertIn(token, root)

    def test_settings_surface_reapplied_on_navigation(self):
        self.assertIn('applySharedAppearance(to: viewController)', GLASS)
        self.assertIn('applySharedAppearance(to: topViewController)', GLASS)
        self.assertIn('super.viewWillAppear(animated)\n        applyGlassSurface()', SETTINGS)
        for key in ['standardAppearance','scrollEdgeAppearance','compactAppearance','compactScrollEdgeAppearance']:
            self.assertIn('page.navigationItem.'+key+' = appearance', GLASS)

    def test_settings_icon_contrast_and_fallback(self):
        for token in ['color.resolvedColor(with: traits)', 'let fill = resolved', 'fill.setFill()', 'UIImage(systemName: "gearshape", withConfiguration: configuration)', 'image.withRenderingMode(.alwaysOriginal)', 'traits: tableView.traitCollection']:
            self.assertIn(token, SETTINGS)
        for name in ['softwareAppearanceMenu', 'dockPositionPage']:
            self.assertNotIn('DerPlayGlassPalette.accent', method(CONTROLLER, name))

    def test_interconnect_menu_order_preserves_persisted_raw_values(self):
        enum = CONTROLLER[CONTROLLER.index('private enum HeadUnitOutput: Int'):CONTROLLER.index('private var airPlayStreamID')]
        self.assertIn('case browser, carLife, airPlay, tailing, ninebot, zeeho, ninebotSeven, ninebot43, zeehoSEPlus, zeehoAE2, cfmoto5, cfmoto62', enum)
        self.assertIn('static let menuOrder: [Self] = [.airPlay, .browser, .carLife, .tailing, .ninebot43, .ninebot, .ninebotSeven, .zeeho, .zeehoSEPlus, .zeehoAE2, .cfmoto5, .cfmoto62]', enum)
        self.assertIn('case .airPlay: return "AirPlay"', enum)
        self.assertIn('case .tailing: return CWL("台铃 4.3 寸")', enum)
        self.assertIn('case .ninebot43: return CWL("九号 4.3 寸")', enum)
        self.assertIn('HeadUnitOutput.init(rawValue:)', CONTROLLER)
        self.assertIn('outputMode.rawValue, forKey: "headUnitOutputV2"', CONTROLLER)

    def test_modes_and_run_guard(self):
        route=method(CONTROLLER,'interconnectRows')
        for token in ['HeadUnitOutput.menuOrder.filter','DerPlayUpstreamBridge.extensionMenuItems()','guard let self, !self.running, !self.waitingForNetwork','self.videoOutputToggled()','self.headUnitOutputChanged()','"尚未开放", icon: (icon, .systemBlue)']:
            self.assertIn(token,route)
    def test_locked_modes_retain_icons(self):
        route=method(CONTROLLER,'interconnectRows')
        self.assertIn('let locked = running || waitingForNetwork',route)
        self.assertLess(route.index('switch mode'),route.index('if locked || wifiAddSavePending {'))
        self.assertIn('return .info(title, selected ? "当前使用" : "停止后可选", icon: icon)',route)
        self.assertIn('SettingsRow.action(title, icon: icon)',route)
        self.assertIn('SettingsRow(title: title, icon: icon, detail: { value }, kind: .info)',SETTINGS)
        self.assertIn('let icon = row.icon ?? fallback',SETTINGS)
        self.assertIn('case .view, .info:',SETTINGS)

    def test_appearance_and_approved_removal(self):
        self.assertNotIn('.control(CWL("驾驶位")',CONTROLLER)
        self.assertIn('config.rightHandDrive = driveControl.selectedSegmentIndex == 1',CONTROLLER)
        self.assertIn('.page(CWL("Dock 栏")',CONTROLLER)
        route=method(CONTROLLER,'dockPositionPage')
        self.assertIn('DerPlayAppearancePreview(night: night, dock:',route)
        self.assertIn('let night = systemAppearanceIsDark',route)
        self.assertIn('布局示意 · 非实际输出',route)
    def test_runtime_methods_are_byte_identical(self):
        self.assertEqual(set(CANDIDATE['methods']), METHODS)
        for name,digest in RUNTIME_METHOD_SHA256.items():
            with self.subTest(name=name):
                if name in METHODS:
                    check_method(self, name, CONTROLLER, method)
                    continue
                body = method(CONTROLLER,name)
                if name in R136_STARTUP_SHA256:
                    self.assertEqual(hashlib.sha256(body.encode()).hexdigest(), R136_STARTUP_SHA256[name])
                    continue
                # R151: reverse reviewed geometry-only edits before historical hash checks.
                if name == 'toggleReceiver':
                    self.assertIn('                                      codec: config.videoCodec, iconWidthMM: config.widthPhysicalMM,\n                                      ratioAdjustedForMinimumSide: planDisplay(for: targetScreen).ratioAdjustedForMinimumSide)\n', body)
                    body = body.replace('                                      codec: config.videoCodec, iconWidthMM: config.widthPhysicalMM,\n                                      ratioAdjustedForMinimumSide: planDisplay(for: targetScreen).ratioAdjustedForMinimumSide)\n', '                                      codec: config.videoCodec, iconWidthMM: config.widthPhysicalMM)\n', 1)
                    self.assertIn('            }\n            receiver.onBrowserGeometryFailure = { [weak self] message in\n                guard let self, self.localStartupID == startupID, self.running, self.outputMode == .browser else { return }\n                self.stop()\n                self.statusLabel.text = message\n                self.refreshDerPlayPanel()\n', body)
                    body = body.replace('            }\n            receiver.onBrowserGeometryFailure = { [weak self] message in\n                guard let self, self.localStartupID == startupID, self.running, self.outputMode == .browser else { return }\n                self.stop()\n                self.statusLabel.text = message\n                self.refreshDerPlayPanel()\n', '', 1)
                    self.assertIn('                        if let plan = self.liveDisplay { live.width = plan.width; live.height = plan.height }\n', body)
                    body = body.replace('                        if let plan = self.liveDisplay { live.width = plan.width; live.height = plan.height }\n', '', 1)
                if name == 'configureDisplay':
                    self.assertIn('        config.displayRatioUnsupported = plan.ratioUnsupported\n        config.browserGeometryBounds = displayGeometryBounds()\n', body)
                    body = body.replace('        config.displayRatioUnsupported = plan.ratioUnsupported\n        config.browserGeometryBounds = displayGeometryBounds()\n', '', 1)
                if name == 'planDisplay':
                    # R156: only the CarLife fixed-axis decoder cap is new.
                    current = 'landscapeBounds: candidates,\n                                                               absoluteBounds: outputMode == .carLife ? .init(width: 1920, height: 1080) : nil) {'
                    self.assertIn(current, body)
                    body = body.replace(current, 'landscapeBounds: candidates) {', 1)
                    self.assertEqual(hashlib.sha256(body.encode()).hexdigest(), '4c3eee051d9a1a5336c06f8193d3c87414210f11ec399382668ef101a8ca7d4d')
                    continue
                # R93: reverse only reviewed, user-authorized method edits for original hash protection.
                for current, prior in {'toggleReceiver': [('            keepAlive.start()\n', '            if keepAliveSwitch.isOn { keepAlive.start() }\n'), ('            keepAlive.start()\n', '            if keepAliveSwitch.isOn { keepAlive.start() }\n'), ('        keepAlive.start()\n', '        if keepAliveSwitch.isOn { keepAlive.start() }\n')], 'stop': [('        displayedVideo = false\n', '        displayedVideo = false; didRequestImmediatePiP = false\n')], 'updatePictureInPicturePolicy': [('        pictureInPicture.setAutomatic(running && displayedVideo && pictureInPictureTiming.selectedSegmentIndex == 1)\n', '        let timing = pictureInPictureTiming.selectedSegmentIndex\n        pictureInPicture.setAutomatic(running && displayedVideo && timing != 0)\n        guard running, displayedVideo, timing == 2, !didRequestImmediatePiP,\n              presentedViewController == nil else { return }\n        didRequestImmediatePiP = true\n        _ = pictureInPicture.start()\n')], 'configureSettingsControls': [('        let savedPiPTiming = defaults.object(forKey: "pictureInPictureTiming") as? Int ?? (legacyPiPEnabled ? 1 : 0)\n        pictureInPictureTiming.selectedSegmentIndex = savedPiPTiming == 0 ? 0 : 1\n        defaults.set(pictureInPictureTiming.selectedSegmentIndex, forKey: "pictureInPictureTiming")\n        defaults.set(pictureInPictureTiming.selectedSegmentIndex == 1, forKey: "pictureInPictureEnabled")\n', '        pictureInPictureTiming.selectedSegmentIndex = defaults.object(forKey: "pictureInPictureTiming") as? Int ?? (legacyPiPEnabled ? 1 : 0)\n'), ('        defaults.set(true, forKey: "backgroundKeepAlive")\n', '        keepAliveSwitch.isOn = defaults.object(forKey: "backgroundKeepAlive") as? Bool ?? true\n        keepAliveSwitch.addTarget(self, action: #selector(keepAliveChanged), for: .valueChanged)\n')]}.get(name, []):
                    self.assertIn(current, body)
                    body = body.replace(current, prior, 1)
                # R29: normalize only the approved visual label refreshes to the frozen baseline.
                if name == 'toggleReceiver':
                    body = body.replace('\n        guard !wifiJoinPending else {\n            statusLabel.text = CWL("请等待系统 Wi-Fi 连接请求完成。")\n            return\n        }', '', 1)
                    for before, after in [
                        ('            refreshDerPlayPanel()\n            log(CWL("正在请求', '            startButton.setTitle(CWL("停止 iPad 连接"), for: .normal)\n            log(CWL("正在请求'),
                        ('            refreshDerPlayPanel()\n            startButton.configuration?.image', '            startButton.setTitle(CWL("停止 CarPlay"), for: .normal)\n            startButton.configuration?.image'),
                        ('                refreshDerPlayPanel()\n                let cap = selectedResolution()', '                startButton.setTitle(CWL("取消连接"), for: .normal)\n                let cap = selectedResolution()'),
                        ('setEditing(false); refreshDerPlayPanel()\n        startButton.configuration?.image', 'setEditing(false); startButton.setTitle(CWL("停止接收"), for: .normal)\n        startButton.configuration?.image')]:
                        body = body.replace(before, after, 1)
                if name == 'startPreparedCarLife':
                    body = body.replace('        refreshDerPlayPanel()\n        statusLabel.text = CWL("正在启动本机 CarPlay…")', '        startButton.setTitle(CWL("停止 CarPlay"), for: .normal)\n        statusLabel.text = CWL("正在启动本机 CarPlay…")', 1)
                if name == 'showFullscreen':
                    body = body.replace('        videoSurface.releaseAllTouches()\n        hidePreviewFullscreenButton()\n', '', 1)
                    body = body.replace('        addFullscreenExitButton(to: container)', '        if !sessionHasVehicleButton { addFullscreenExitButton(to: container) }')
                if name == 'hideFullscreen':
                    body = body.replace('        videoSurface.releaseAllTouches()\n', '', 1).replace('        hidePreviewFullscreenButton()\n', '', 1)
                if name == 'stop':
                    body = body.replace('reportedScreen = nil; primaryViewer = nil; browserGeometryResolvedForSession = false; pendingRestartReason = nil', 'reportedScreen = nil; primaryViewer = nil; pendingRestartReason = nil')
                    body = body.replace('hideFullscreen(); hidePreviewFullscreenButton()', 'hideFullscreen(); videoActions.isHidden = true; controlBar.isHidden = true')
                    # R96/R97: normalize only approved AirPlay policy/diagnostic resets.
                    # R99: retain the original stop hash after removing only the three explicit KVO invalidations.
                    for observation in ('airPlayItemObservation', 'airPlayRouteObservation', 'airPlayTimeObservation'):
                        line = f'        {observation}?.invalidate()\n'
                        self.assertIn(line, body)
                        body = body.replace(line, '', 1)
                    body = body.replace('        airPlayTransportRecovery.reset()\n', '', 1)
                    body = body.replace('        airPlayBufferTelemetry.reset()\n', '', 1)
                if name == 'configureDisplay':
                    body = body.replace('        config.browserAutoAdaptBeforeCarPlay = outputMode == .browser && modeControl.selectedSegmentIndex == 1 && followsCarScreen && config.videoOutputPort != nil\n', '')
                    body = body.replace('config.oemIconPNG = customVehicleIcon ?? defaultVehicleIcon()', 'config.oemIconPNG = customVehicleIcon ?? Self.carButtonIcon', 1)
                    body = body.replace('\n        config.dockPosition = DerPlayDockPosition.saved()', '')
                if name in ('toggleReceiver', 'stop'):
                    body = body.replace('\n        cancelAutomaticRestart()', '', 1)
                if name == 'toggleReceiver':
                    body = body.replace('                        // Remember the user\'s video preferences separately from the fixed CarLife wire format.\n                        self.carLifeProfileDefaultFPSIndex = self.frameRateControl.selectedSegmentIndex\n                        self.carLifeProfileDefaultCodecIndex = self.codecControl.selectedSegmentIndex\n                        let defaultFPS = [0, 30, 60][max(0, self.frameRateControl.selectedSegmentIndex)]\n                        let defaultCodec = ["auto", "h264", "h265"][max(0, self.codecControl.selectedSegmentIndex)]\n                        let video = savedLayout?.videoPreference(fallbackFPS: defaultFPS, fallbackCodec: defaultCodec)\n                        self.frameRateControl.selectedSegmentIndex = [0, 30, 60].firstIndex(of: video?.fps ?? defaultFPS) ?? 1\n                        self.codecControl.selectedSegmentIndex = ["auto", "h264", "h265"].firstIndex(of: video?.codec ?? defaultCodec) ?? 1\n', '')
                    body = body.replace('                    // CarLife currently supports only the iPhone audio route. Retain a\n                    // saved preference without enabling unsupported protocol audio.\n                    let preferredSound = savedLayout?.soundOutput.flatMap(SoundOutput.init(rawValue:)) ?? self.selectedSoundOutput\n                    let showVehicleButton = savedLayout?.carButton ?? self.carButtonSwitch.isOn\n                    if showVehicleButton {\n                        negotiated.oemIconPNG = self.customVehicleIcon ?? self.defaultVehicleIcon(appearanceIndex: savedLayout?.appearance)\n                        let label = String((self.nameField.text ?? "").prefix(12))\n                        negotiated.oemIconLabel = label.isEmpty ? "DerPlay" : label\n                    } else {\n                        negotiated.oemIconPNG = nil\n                    }\n', '')
                    body = body.replace('                        self.carLifeProfileDefaultSound = self.selectedSoundOutput\n                        self.selectedSoundOutput = preferredSound\n                        self.carLifeProfileDefaultCarButton = self.carButtonSwitch.isOn\n                        self.carButtonSwitch.isOn = showVehicleButton\n', '')
                    body = body.replace('                    let savedLayout = DeviceProfilePolicy().lookup(scope: self.currentPreferenceScope, evidence: geometry)\n                    negotiated.rightHandDrive = savedLayout?.rightHandDrive ?? config.rightHandDrive\n                    negotiated.dockPosition = (savedLayout?.dockPosition).flatMap { DerPlayDockPosition(rawValue: $0) } ?? config.dockPosition\n', '')
                    body = body.replace('                        self.carLifeProfileDefaultAppearance = self.appearanceControl.selectedSegmentIndex\n                        if let appearance = savedLayout?.appearance, (0...2).contains(appearance) {\n                            self.appearanceControl.selectedSegmentIndex = appearance\n                        }\n                        self.carLifeProfileDefaultDrive = self.driveControl.selectedSegmentIndex\n                        self.driveControl.selectedSegmentIndex = negotiated.rightHandDrive ? 1 : 0\n                        self.carLifeProfileDock = negotiated.dockPosition\n                        self.saveMatchedCarLifeLayout()\n                        self.applyAppearance()\n', '                        DeviceProfilePolicy().save(.init(resolutionIndex: tier, aspectRatio: "auto", iconWidthMM: negotiated.widthPhysicalMM),\n                                                   scope: self.currentPreferenceScope, evidence: geometry)\n')
                    body = body.replace('\n        clearCarLifeProfileProjection()', '', 1)
                    body = body.replace('receiver.prepareCarLife(configuration: config, area: area, direction: carLifeDirection,\n                    profileAreas: ReceiverConfiguration.resolutions.map { min($0.width * $0.height, 1920 * 1080) },\n                    profileFallbackIndex: resolutionControl.selectedSegmentIndex) { [weak self] width, height, fps, rawWidth, rawHeight, tier in', 'receiver.prepareCarLife(configuration: config, area: area, direction: carLifeDirection) { [weak self] width, height, fps in')
                    body = body.replace('                    let geometry = DeviceProfilePolicy.Evidence.screenGeometry(rawWidth, rawHeight)\n                    negotiated.widthPhysicalMM = DeviceProfilePolicy().iconWidthMM(\n                        scope: self.currentPreferenceScope, evidence: geometry,\n                        fallback: config.widthPhysicalMM, allowed: ReceiverConfiguration.iconSizes.map { $0.widthMM })\n', '')
                    body = body.replace('                    if ReceiverConfiguration.resolutions.indices.contains(tier),\n                       DeviceProfilePolicy.key(scope: self.currentPreferenceScope, evidence: geometry) != nil {\n                        self.lastCarLifeGeometry = geometry\n                        self.carLifeProfileDefaultIndex = self.resolutionControl.selectedSegmentIndex\n                        self.resolutionControl.selectedSegmentIndex = tier\n                        self.carLifeProfileDefaultIconIndex = self.iconSizeControl.selectedSegmentIndex\n                        self.iconSizeControl.selectedSegmentIndex = ReceiverConfiguration.iconSizes.firstIndex {\n                            $0.widthMM == negotiated.widthPhysicalMM\n                        } ?? self.iconSizeControl.selectedSegmentIndex\n                        DeviceProfilePolicy().save(.init(resolutionIndex: tier, aspectRatio: "auto", iconWidthMM: negotiated.widthPhysicalMM),\n                                                   scope: self.currentPreferenceScope, evidence: geometry)\n                        self.log("CarLife：屏幕配置匹配 \\(rawWidth)×\\(rawHeight)，分辨率档位 \\(tier)。")\n                    }\n', '')
                    body = body.replace('\n            receiver.onBrowserDisplay = { [weak self] display, viewerID in\n                guard let self, self.localStartupID == startupID else { return }\n                self.browserReportedDisplay(display, viewerID: viewerID)\n            }\n            receiver.onBrowserStruggling = { [weak self] peer, reason in\n                guard let self, self.localStartupID == startupID, self.running, self.outputMode == .browser else { return }\n                self.browserStruggling(peer: peer, reason: reason)\n            }', "")
                    body = body.replace('\n                    if let screen = self.carLifeScreen { CarScreenStore.recordCarLifeNegotiation(screen) }', '')
                if name == 'appearanceChanged':
                    body = body.replace('        if carLifeProfileDefaultAppearance != nil {\n            saveMatchedCarLifeLayout()\n        } else {\n            UserDefaults.standard.set(appearanceControl.selectedSegmentIndex, forKey: "carPlayAppearance")\n        }\n', '        UserDefaults.standard.set(appearanceControl.selectedSegmentIndex, forKey: "carPlayAppearance")\n')
                if name == 'videoOutputToggled':
                    body = body.replace('guard !running, !waitingForNetwork else', 'guard !running else')
                    body = body.replace('\n        restoreProtocolPreferences()', '').replace('\n        updateVideoAspect()', '')
                if name == 'headUnitOutputChanged':
                    body = body.replace('\n        guard !running, !waitingForNetwork else { return }\n        restoreProtocolPreferences()', '')
                if name == 'setEditing':
                    body = body.replace('\n        browserViewAreaProbeSwitch.isEnabled = value', '')
                if name == 'configureSettingsControls':
                    # R144: reconstruct only removed accessory UI for original hash comparison.
                    body = body.replace('            field.addTarget(self, action: #selector(saveBrowserPorts), for: .editingDidEnd)\n', '            field.addTarget(self, action: #selector(saveBrowserPorts), for: .editingDidEnd)\n            let toolbar = UIToolbar()\n            toolbar.items = [.flexibleSpace(), UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak field] _ in\n                field?.resignFirstResponder()\n            })]\n            toolbar.sizeToFit()\n            field.inputAccessoryView = toolbar\n', 1)
                    body = body.replace('            $0.addTarget($0, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)\n', '            $0.addTarget($0, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)\n            if $0.inputAccessoryView == nil {\n                let field = $0\n                let toolbar = UIToolbar()\n                toolbar.items = [.flexibleSpace(), UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak field] _ in\n                    field?.resignFirstResponder()\n                })]\n                toolbar.sizeToFit()\n                field.inputAccessoryView = toolbar\n            }\n', 1)
                    body = body.replace('WiFiPresetStore.legacyChannel()', 'UInt8(UserDefaults.standard.object(forKey: "wifiChannel") as? Int ?? 36)', 1)
                    body = body.replace('\n        carButtonSwitch.addTarget(self, action: #selector(rememberCarLifeResolution), for: .valueChanged)', '')
                    body = body.replace('\n        iconSizeControl.addTarget(self, action: #selector(rememberCarLifeResolution), for: .valueChanged)', '')
                    body = body.replace('\n        resolutionControl.addTarget(self, action: #selector(rememberCarLifeResolution), for: .valueChanged)', '')
                    body = body.replace('\n        preferenceScope = currentPreferenceScope', '').replace('\n        DerPlayProtocolPreferences(defaults: defaults).recoverPendingTransition()', '')
                if name == 'toggleReceiver':
                    body = body.replace('reportedScreen = nil; primaryViewer = nil; browserGeometryResolvedForSession = false', 'reportedScreen = nil; primaryViewer = nil')
                    body = body.replace('''            statusLabel.text = config.browserAutoAdaptBeforeCarPlay
                ? CWL("等待接收设备打开访问地址，以识别屏幕尺寸…") : CWL("正在启动本机 CarPlay…")
''', '            statusLabel.text = CWL("正在启动本机 CarPlay…")\n')
                    body = body.replace('''            receiver.onBrowserGeometryResolved = { [weak self] width, height, adjusted in
                guard let self, self.localStartupID == startupID, self.running,
                      self.outputMode == .browser, self.followsCarScreen else { return }
                var plan = self.liveDisplay ?? self.planDisplay(for: self.reportedScreen)
                plan.width = width; plan.height = height; plan.ratioAdjustedForMinimumSide = adjusted
                self.liveDisplay = plan
                self.browserGeometryResolvedForSession = true
                self.updateVideoAspect()
                self.reloadVisibleSettings()
                self.refreshDerPlayPanel()
            }
''', '')
                    body = body.replace('''                    if config.browserAutoAdaptBeforeCarPlay {
                        self.statusLabel.text = CWL("已识别接收设备屏幕，正在启动 CarPlay…")
                    }
''', '')
                if name == 'toggleReceiver':
                    body = body.replace('                if outputMode.usesInstrumentWiFi {\n                    watchInstrumentStartupRecovery(expectedSSID: config.ssid, startupID: startupID)\n                } else {\n                    watchStartupAddress(address)\n                }', '                watchStartupAddress(address)')
                if name == 'toggleReceiver':
                    body = body.replace('        if prepareStartupWiFi() { return }\n', '')
                if name == 'stop':
                    body = body.replace('        airPlayLastRecoveryAt = nil\n        airPlayRecoveryCount = 0\n        resetAirPlayProgress()\n', '')
                    body = body.replace('        startupWiFiTicket = nil\n', '')
                    body = body.replace('        instrumentRecoveryProbe.stop()\n        instrumentRecoveryResult = nil\n', '')
                    body = body.replace('        runtimeNetworkRecovery.stop()\n        runtimeNetworkRecoveryWork?.cancel(); runtimeNetworkRecoveryWork = nil\n        backgroundNetworkAddress = nil\n', '')
                # R128: user-requested Wi-Fi save gate only; retain original runtime method hashes.
                if name == 'toggleReceiver':
                    body = body.replace('        guard !wifiAddSavePending else {\n            statusLabel.text = CWL("请等待 Wi-Fi 预设保存完成。")\n            return\n        }\n', '')
                if name == 'saveCurrentWiFiPreset':
                    body = body.replace('        guard !wifiAddSavePending else { return false }\n', '')
                # R132: only the two read-pending guards may differ from the original startup body.
                if name == 'toggleReceiver':
                    body = body.replace('        guard !needsNetworkDetails || !wifiPasswordReadPending else {\n            statusLabel.text = CWL("请稍候")\n            return\n        }\n', '')
                if name == 'saveCurrentWiFiPreset':
                    body = body.replace('        guard !wifiAddSavePending, !wifiPasswordReadPending else { return false }\n', '')
                self.assertEqual(hashlib.sha256(body.encode()).hexdigest(),digest)
    def test_software_theme_does_not_override_system_ancestor(self):
        theme=method(CONTROLLER,'applySoftwareAppearance')
        self.assertIn('overrideUserInterfaceStyle = style',theme)
        self.assertIn('navigationController?.navigationBar.overrideUserInterfaceStyle = style',theme)
        self.assertIn('settingsNavigation?.overrideUserInterfaceStyle = style',theme)
        self.assertNotIn('navigationController?.overrideUserInterfaceStyle',theme)
        self.assertNotIn('window?.overrideUserInterfaceStyle',theme)
        self.assertIn('navigationController?.traitCollection.userInterfaceStyle',CONTROLLER)
        self.assertIn('parentView.addSubview(systemAppearanceObserver)',CONTROLLER)
        self.assertIn('registerForTraitChanges([UITraitUserInterfaceStyle.self])',GLASS)
        self.assertIn('if #unavailable(iOS 17.0)',GLASS)
        self.assertIn('navigation.overrideUserInterfaceStyle = DerPlaySoftwareAppearance.saved().style',method(CONTROLLER,'revealSettings'))
        self.assertIn('let night = systemAppearanceIsDark',method(CONTROLLER,'applyAppearance'))
        self.assertIn('receiver.setNightMode(night)',method(CONTROLLER,'applyAppearance'))
        self.assertIn('UIApplication.shared.applicationState != .background',method(CONTROLLER,'applyAppearance'))
        self.assertIn('let night = systemAppearanceIsDark',method(CONTROLLER,'dockPositionPage'))
    def test_software_theme_storage_is_independent(self):
        route=method(CONTROLLER,'softwareAppearanceMenu')
        self.assertIn('let choices: [DerPlaySoftwareAppearance] = [.dark, .light]',route)
        self.assertIn('forKey: DerPlaySoftwareAppearance.defaultsKey',route)
        self.assertIn('self?.applySoftwareAppearance()',route)
        self.assertNotIn('appearanceControl',route)
        self.assertIn('defaultsKey = "derplay.softwareAppearance"',GLASS)
        self.assertIn('return .light',GLASS)
    def test_menu_relocation_preserves_entry_points(self):
        root=method(CONTROLLER,'rootSettingsPage')
        connection=method(CONTROLLER,'connectionSettingsPage')
        for route in ['headUnitPage()', 'wifiPage()', 'httpsSettingsPage()', 'vehiclePage()', 'pictureRatioMenu()', 'browserExperimentsPage()']:
            self.assertIn(route,connection)
            self.assertNotIn(route,root)
        for route in ['pictureInPictureTiming', 'softwareAppearanceMenu()', 'derPlayIdentityPage()', 'aboutPage()']:
            self.assertIn(route,root)
        self.assertEqual(root.count('.page('),3)
        self.assertNotIn('diagnosticsPage()',root)
        self.assertNotIn('soundPage()',connection)
        self.assertLess(root.index('夜间模式'), root.index('pictureInPictureTiming'))
        self.assertNotIn('backgroundSettingsPage()', root)
        for route in ['displayPage()', 'presetsPage()', 'screensPage()']:
            self.assertNotIn(route,connection)
            self.assertNotIn(route,root)
        self.assertIn('usagePage()',root)
        self.assertLess(root.index('usagePage()'),root.index('夜间模式'))
        self.assertNotIn('usagePage()',method(CONTROLLER,'aboutLinks'))
        self.assertIn('headUnitOutputChanged()',method(CONTROLLER,'interconnectRows'))
    def test_flat_mode_specific_routes(self):
        connection=method(CONTROLLER,'connectionSettingsPage')
        self.assertIn('if needsNetworkDetails',connection)
        self.assertNotIn('self.soundPage()',connection)
        self.assertIn('iconSizeControl',connection)
        self.assertIn('if !outputMode.usesInstrumentWiFi',connection)
        self.assertIn('outputMode == .browser && videoOutputSwitch.isOn',connection)
        self.assertIn('carLifeAddressField, placeholder: CWL("留空自动发现")',connection)
        self.assertIn('else if outputMode.usesInstrumentWiFi',connection)
        self.assertIn('self.antBMS.settingsPage()',connection.split('else if outputMode.usesInstrumentWiFi')[1])
        self.assertNotIn('autoRestartSwitch',connection)
        experiments=method(CONTROLLER,'browserExperimentsPage')
        self.assertIn('autoRestartSwitch',experiments)
        self.assertIn('experimentalBrowserViewAreasKey',experiments)
        self.assertNotIn('experimentalBrowserViewAreasKey',method(CONTROLLER,'aboutDeviceSection'))
        ratio=method(CONTROLLER,'pictureRatioMenu')
        for token in ['availableAspectRatios.map', 'index == 0 ? 0 : 1', 'index - 1', 'self.displaySettingChanged()', 'guard !self.running, !self.waitingForNetwork']:
            self.assertIn(token,ratio)

    def test_dashboard_has_no_legacy_connection_cards(self):
        self.assertIn('let stack = UIStackView(arrangedSubviews: [dashboardHost.view])', CONTROLLER)
        self.assertNotIn('heroStack', CONTROLLER)
        for card in ['browserCard', 'carLifeCard', 'zeehoCard', 'cfmotoCard', 'ninebotCard', 'tailingCard', 'airPlayCard']:
            self.assertNotIn('stack.addArrangedSubview('+card+')', CONTROLLER)
        connection = method(CONTROLLER, 'connectionSettingsPage')
        for token in ['carPlayRows.append(.view(receiverPicker))', 'carPlayRows.append(.view(airPlayRetryButton))']:
            self.assertIn(token, connection)
        self.assertNotIn('airPlayRoutePicker', connection)
        self.assertNotIn('SettingsSection(CWL("连接状态")', connection)
        self.assertNotIn('.note(browserViewersLabel)', method(CONTROLLER, 'browserOutputSections'))
        home = method(CONTROLLER, 'refreshDashboardStatus')
        for label in ['statusLabel', 'startupHint', 'carLifeStatus', 'airPlayStatus', 'browserViewersLabel', 'ninebotStatus', 'zeehoStatus', 'tailingStatus', 'cfmotoStatus']:
            self.assertIn(label, home)
        self.assertIn('glassDashboardState.statusLines = lines', home)
        self.assertIn('if !state.statusLines.isEmpty', GLASS)
        self.assertIn('StatusLabel.didChange, object: nil', CONTROLLER)
        self.assertIn('browserAddressRow(secure: false)', method(CONTROLLER, 'browserOutputSections'))
        self.assertIn('browserAddressRow(secure: true)', method(CONTROLLER, 'httpsSettingsPage'))

    def test_home_airplay_native_picker_and_ratio_menu(self):
        home = method(CONTROLLER, 'refreshDashboardStatus')
        self.assertIn('outputMode == .airPlay && !isLocalCarPlayOnly', home)
        self.assertIn('showAirPlay && running && airPlayReady', home)
        self.assertIn('airPlayPicker: airPlayRoutePicker', method(CONTROLLER, 'makeDerPlayConnectionPanel'))
        self.assertIn('if state.showsAirPlayPicker', GLASS)
        self.assertIn('DerPlayHomeAirPlayPicker(picker: airPlayPicker)', GLASS)
        self.assertIn('Button(action: openAirPlayPicker)', GLASS)
        self.assertIn('.disabled(!state.airPlayPickerReady)', GLASS)
        ratio = method(CONTROLLER, 'pictureRatioMenu')
        self.assertNotIn('预设比例', ratio)
        self.assertIn('$0.offset + 2', ratio)
        self.assertIn('pictureMenuIndex == 1', ratio)
        self.assertIn('nativePresetRatioTitle', ratio)

    def test_dashboard_status_uses_card_leading_inset(self):
        status = GLASS.split('if !state.statusLines.isEmpty', 1)[1].split('.foregroundStyle(.primary)', 1)[0]
        self.assertIn('.multilineTextAlignment(.leading)', status)
        self.assertIn('.frame(maxWidth: .infinity, alignment: .leading)', status)
        self.assertIn('.padding(.horizontal, 16)', status)
        self.assertNotIn('.padding(.leading', status)

    def test_bms_is_retained_for_instrument_modes(self):
        connection = method(CONTROLLER, 'connectionSettingsPage')
        self.assertEqual(connection.count('self.antBMS.settingsPage()'), 1)
        self.assertIn('self.antBMS.settingsPage()', connection.split('else if outputMode.usesInstrumentWiFi')[1])
        self.assertIn('retryAirPlayTransport()', CONTROLLER)

    def test_sheet_height_and_dismissal(self):
        self.assertIn('if heightLocked { return min(limit, lastResolvedHeight ?? limit) }',GLASS)
        self.assertIn('if viewController !== viewControllers.first { heightLocked = true }',GLASS)
        self.assertIn('guard !heightLocked, viewControllers.count == 1',GLASS)
        self.assertIn('guard !self.heightLocked, self.viewControllers.count == 1',GLASS)
        self.assertNotIn('measuredPage',GLASS)
        self.assertEqual(GLASS.count('invalidateDetents()'),1)
        self.assertIn('if viewControllers.count > 1 { heightLocked = true }',GLASS)
        self.assertIn('guard settingsNavigation != nil else { return }',method(CONTROLLER,'settingsDismissed'))
        self.assertIn('presentationController.presentedViewController === settingsNavigation',CONTROLLER)
    def test_control_buttons_keep_callbacks(self):
        self.assertIn('DerPlayGlassPalette.styleAction(button, radius: 16)',method(CONTROLLER,'makeControlButton'))
        self.assertIn('self?.receiver.press(control)',method(CONTROLLER,'makeControlButton'))
        self.assertIn('inlineVideoContainer.addSubview(fullscreenButton)',CONTROLLER)
        self.assertIn('#selector(showFullscreen)',CONTROLLER)
        self.assertIn('func startPictureInPicture()',CONTROLLER)
        self.assertIn('.home, .back, .siri, .previous, .playPause, .next, .hookSwitch',CONTROLLER)

    def test_dock_settings_use_snapshot_and_guard(self):
        route=method(CONTROLLER,'dockPositionPage')
        for token in ['DerPlayDockPosition.allCases','!self.running, !self.waitingForNetwork','UserDefaults.standard.set(choice.rawValue','self.reloadVisibleSettings()']:
            self.assertIn(token,route)
        self.assertIn('config.dockPosition = DerPlayDockPosition.saved()',method(CONTROLLER,'configureDisplay'))
        self.assertIn('if dock == .bottom',GLASS)

    def test_r29_primary_action_and_title(self):
        for token in ['playbackHomeSlot.heightAnchor.constraint(equalToConstant: 80)', 'derPlayTitle.font = UIFont.systemFont(ofSize: 36, weight: .bold)', 'inlineVideoShadow.addSubview(inlineVideoContainer)', 'inlineVideoContainer.clipsToBounds = true']:
            self.assertIn(token, CONTROLLER)
        body = method(CONTROLLER, 'refreshDerPlayPanel')
        for token in ['active ? CWL("停止") : CWL("启动")', 'active ? "stop.fill" : "play.fill"', 'active ? DerPlayGlassPalette.stopRed : DerPlayGlassPalette.startGreen', 'inlineVideoShadow.isHidden = !displayedVideo']:
            self.assertIn(token, body + method(GLASS, "updateButtonAppearance"))
        self.assertNotIn('startButton.setTitle(', CONTROLLER)
        self.assertIn('shadowOpacity = view.traitCollection.userInterfaceStyle == .dark ? 0.65 : 0.32', GLASS)
        self.assertIn('red: 52.0 / 255, green: 199.0 / 255, blue: 89.0 / 255', GLASS)
        self.assertIn('red: 255.0 / 255, green: 59.0 / 255, blue: 48.0 / 255', GLASS)

    def test_r34_native_title_preserves_shadow(self):
        body = method(CONTROLLER, 'viewDidLoad')
        self.assertIn('derPlayTitle.font = UIFont.systemFont(ofSize: 36, weight: .bold)', body)
        self.assertNotIn('withDesign(.rounded)', body)
        self.assertIn('DerPlayGlassPalette.shadow(derPlayTitle, radius: 6, offset: 3)', body)
        self.assertIn('derPlayTitle.layer.shadowOpacity = 0.16', body)
        self.assertIn('derPlayTitle.textColor = DerPlayGlassPalette.accent', body)

    def test_project_includes_ui(self):
        source='App/DerPlayGlassUI.swift'
        project=(ROOT/'TDSCarKit.xcodeproj/project.pbxproj').read_text()
        ref=hashlib.sha1(('ref:'+source).encode()).hexdigest()[:24].upper()
        build=hashlib.sha1(('build:'+source).encode()).hexdigest()[:24].upper()
        self.assertIn('path = "'+source+'"',project)
        self.assertRegex(project,r'isa = PBXSourcesBuildPhase;[^\n]*'+build)
        self.assertRegex(project,r'isa = PBXGroup; children = \([^\n]*'+ref)

if __name__=='__main__': unittest.main()
