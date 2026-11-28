"""R150 guards for clarity bounds, device-native ratios, and connection settings presentation."""
import json
import unittest
from pathlib import Path
from test_glass_ui import CONTROLLER, GLASS, SETTINGS, ROOT, method

class DisplayGeometryAndSettingsTests(unittest.TestCase):
    def test_builtin_ratio_order_and_dynamic_native_ratio_source(self):
        config=(ROOT/'App/ReceiverConfiguration.swift').read_text()
        block=config.split('static let aspectRatios = [',1)[1].split(']',1)[0]
        ratios=[]
        import re
        ratios=re.findall(r'width: (\d+), height: (\d+)',block)
        self.assertEqual(ratios,[('32','9'),('21','9'),('16','9'),('16','10'),('4','3'),('4','1'),('3','2'),('3','1'),('1','1'),('9','16'),('3','4')])
        self.assertIn('CarScreenStore.screens().compactMap',CONTROLLER)
        self.assertIn('screen.nativeWidth',CONTROLLER)
        self.assertIn('screen.nativeHeight',CONTROLLER)
        store=(ROOT/'App/CarScreenStore.swift').read_text()
        self.assertIn('nativeWidth: display.screenWidth, nativeHeight: display.screenHeight',store)
        self.assertIn('DisplayGeometry.orderedRatios',config)

    def test_clarity_labels_do_not_claim_fixed_raster(self):
        self.assertIn('ReceiverConfiguration.resolutions.map(\\.label)',CONTROLLER)
        self.assertIn('CWL("清晰度")',method(CONTROLLER,'connectionSettingsPage'))
        self.assertIn('CWL("实际输出分辨率")',method(CONTROLLER,'connectionSettingsPage'))
        self.assertIn('actualOutputResolutionLabel(for: previewPlan)',method(CONTROLLER,'connectionSettingsPage'))
        self.assertIn('CWL("清晰度")',method(CONTROLLER,'displayPage'))

    def test_geometry_hard_bounds_rotates_for_portrait_and_minimum_side(self):
        geometry=(ROOT/'DerPlay/Extensions/DisplayGeometry.swift').read_text()
        plan=method(CONTROLLER,'planDisplay')
        for token in ['DisplayGeometry.orientedBounds','DisplayGeometry.fit','maxLandscapeWidth','maxLandscapeHeight']:
            self.assertIn(token,plan)
        self.assertIn('minimumShortSide: Int = 320',geometry)
        self.assertIn('adjustedForMinimumSide',geometry)
        smoke=(ROOT/'Tools/derplay/DisplayGeometrySmoke.swift').read_text()
        for token in ['594, height: 1254','1280, height: 320','320, height: 1280','ratioHeight: 5']:
            self.assertIn(token,smoke)

    def test_connection_settings_grouping_and_labels(self):
        page=method(CONTROLLER,'connectionSettingsPage')
        self.assertIn('page(CWL("连接模式"), firstCardTopSpacing: 12)',page)
        self.assertIn('SettingsSection(networkRows)',page)
        self.assertIn('SettingsSection(CWL("CarPlay 设置"), footer: editingLockedFooter, carPlayRows)',page)
        self.assertNotIn('CWL("声音设置")',page)
        self.assertNotIn('CWL("昼夜模式")',page)
        self.assertIn('CWL("Dock 栏")',page)
        self.assertIn('CWL("Wi-Fi 网络")',page)
        self.assertNotIn('Wi-Fi 与网络',page)

    def test_home_glass_and_airplay_screen_icon(self):
        self.assertIn('menuRow(CWL("通用设置"), symbol: "gearshape", action: settings)',GLASS)
        self.assertIn('menuRow(CWL("连接模式"), symbol: "car", value: state.mode, action: connection)',GLASS)
        self.assertNotIn('glassEffect(.regular, in: Circle())',GLASS)
        self.assertNotIn('Circle().fill(.ultraThinMaterial)',GLASS)
        self.assertNotIn('.routePickerButtonStyle', CONTROLLER)
        self.assertNotIn('.isRoutePickerButtonBordered', CONTROLLER)
        self.assertIn('airPlayRoutePicker.prioritizesVideoDevices = true', CONTROLLER)
        self.assertIn('DerPlayHomeAirPlayPicker(picker: airPlayPicker)', GLASS)
        self.assertIn('Image(systemName: "airplayvideo")',GLASS)
        self.assertIn('foregroundStyle(scheme == .dark ? Color.white : Color.black)',GLASS)
        self.assertIn('derPlayTitle.layer.shadowOpacity = 0.16',CONTROLLER)

    def test_settings_sheet_has_shared_playback_control(self):
        route=method(CONTROLLER,'prepareConnectionLayer')
        self.assertIn('navigation.reservesConnectionPlayback = true',route)
        self.assertIn('layer.installContent(navigation.view)',route)
        self.assertIn('connectionControlLayer?.active = active',method(CONTROLLER,'refreshDerPlayPanel'))
        self.assertIn('nativeButtonConfiguration(prominent: true)',CONTROLLER)
        self.assertIn('DerPlayGlassPalette.stopRed',CONTROLLER)
        self.assertIn('DerPlayGlassPalette.startGreen',CONTROLLER)
        self.assertIn('#selector(connectionPlaybackTapped)',CONTROLLER)
        self.assertIn('clearTrailingPlaybackControls(on:',GLASS)

    def test_localization_keys(self):
        for path in ['App/Localization/Localizable.xcstrings','docs/localization/en/Localizable.xcstrings']:
            strings=json.loads((ROOT/path).read_text())['strings']
            for key in ['通用设置','连接模式','互联协议','Wi-Fi 网络','CarPlay 设置','昼夜模式','Dock 栏','清晰度','实际输出分辨率','连接后识别']:
                self.assertIn(key,strings)
                self.assertTrue(strings[key]['localizations']['en']['stringUnit']['value'])

if __name__=='__main__': unittest.main(verbosity=2)
