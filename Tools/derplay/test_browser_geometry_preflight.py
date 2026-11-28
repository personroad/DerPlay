"""Preflight geometry guards for browser-fed CarPlay display negotiation."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
class BrowserGeometryPreflightTests(unittest.TestCase):
    def test_preflight_is_enabled_only_for_local_browser_follow_screen(self):
        config=(ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('config.browserAutoAdaptBeforeCarPlay = outputMode == .browser && modeControl.selectedSegmentIndex == 1 && followsCarScreen && config.videoOutputPort != nil',config)
        self.assertIn('等待接收设备打开访问地址，以识别屏幕尺寸',config)
        self.assertIn('browserGeometryPreflightNeedsAddress',config)
        self.assertIn('DisplayGeometry.fillsScreen(viewportWidth: display.width',config)
        self.assertIn('请在接收设备浏览器点全屏按钮',config)
        self.assertIn("fullscreenChanged(){document.body.classList.toggle('fullscreen',isFullscreen());wake();clearTimeout(resizeTimer);resizeTimer=setTimeout(sendDisplay,300)}", (ROOT/'App/BrowserReceiverPage.swift').read_text())
        self.assertIn('CWL("访问地址：{1}",',config)
        self.assertNotIn('未检测到接收屏幕尺寸，使用默认画面比例启动',config)

    def test_browser_http_listener_starts_before_carplay_advertising(self):
        native=(ROOT/'App/NativeReceiver.swift').read_text()
        start=native.split('func start(configuration:',1)[1].split('private func finishBrowserGeometryStartup',1)[0]
        self.assertLess(start.index('self.videoOutput.start('),start.index('self.listen(configuration: configuration'))
        self.assertIn('self.browserGeometryStartupPending = configuration.browserAutoAdaptBeforeCarPlay',start)
        self.assertIn('finishBrowserGeometryStartup(display: display',start)
        self.assertIn('browserDisplayFillsScreen(display)',start)
        self.assertIn('browserGeometryWaitingForFullscreenLogged',start)
        self.assertIn('DisplayGeometry.fillsScreen',native)
        self.assertIn('coverageTolerance: Double = 0.03', (ROOT/'DerPlay/Extensions/DisplayGeometry.swift').read_text())
        self.assertIn('self.queue.asyncAfter(deadline: .now() + 45, execute: timeout)',start)

    def test_timeout_never_advertises_default_geometry(self):
        native=(ROOT/'App/NativeReceiver.swift').read_text()
        timeout=native.split('let timeout = DispatchWorkItem',1)[1].split('self.browserGeometryStartupTimeout = timeout',1)[0]
        self.assertIn('self.generation == displayGeneration',timeout)
        self.assertIn('self.failBrowserGeometry(',timeout)
        self.assertNotIn('self.listen(',timeout)
        self.assertNotIn('onBrowserGeometryResolved',timeout)

    def test_resolution_callback_is_captured_and_status_is_not_reset(self):
        native=(ROOT/'App/NativeReceiver.swift').read_text()
        self.assertIn('let onResolved = self.onBrowserGeometryResolved',native)
        self.assertIn('onResolved?(resolved.width, resolved.height',native)
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('followsCarScreen, !browserGeometryResolvedForSession, let display',ui)

    def test_real_viewport_is_applied_before_first_info_listener(self):
        native=(ROOT/'App/NativeReceiver.swift').read_text()
        finish=native.split('private func finishBrowserGeometryStartup',1)[1].split('private func listen(',1)[0]
        for token in ['display.width, ratioHeight: display.height','configuration.browserGeometryBounds','DisplayGeometry.fitPreservingRatio','videoOutput.updateOutputSize','self.displaySize = (resolved.width, resolved.height)','self.listen(configuration: resolved']:
            self.assertIn(token,finish)
        self.assertLess(finish.index('videoOutput.updateOutputSize'),finish.index('self.listen(configuration: resolved'))
        self.assertIn('browserGeometryStartupTimeout?.cancel()',finish)
        server=(ROOT/'App/VideoOutputServer.swift').read_text()
        update=server.split('func updateOutputSize',1)[1].split('func stop()',1)[0]
        self.assertIn('self.clients.values.allSatisfy({ !$0.streamStarted })',update)
        self.assertIn('self.width = width; self.height = height',update)

    def test_known_incompatible_geometry_does_not_start_default_raster(self):
        native=(ROOT/'App/NativeReceiver.swift').read_text()
        finish=native.split('private func finishBrowserGeometryStartup',1)[1].split('private func listen(',1)[0]
        self.assertIn('failBrowserGeometry',finish)
        self.assertNotIn('listen(configuration: configuration',finish)
        self.assertIn('stopOnQueue()',finish)
        self.assertIn('guard !displayRatioUnsupported else',(ROOT/'App/ReceiverConfiguration.swift').read_text())

    def test_carplay_info_declares_resolved_pixels_and_hid_coordinates(self):
        info=(ROOT/'App/CarPlayInfo.swift').read_text()
        self.assertIn('"widthPixels": config.width, "heightPixels": config.height',info)
        self.assertIn('touchDescriptor(width: config.width, height: config.height)',info)

    def test_native_resolution_updates_ui_and_dynamic_ratio_history(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        self.assertIn('receiver.onBrowserGeometryResolved =',ui)
        self.assertIn('plan.ratioAdjustedForMinimumSide = adjusted',ui)
        self.assertIn('self.browserGeometryResolvedForSession = true',ui)
        self.assertIn('screen.nativeWidth',ui)
        self.assertIn('screen.nativeHeight',ui)
        store=(ROOT/'App/CarScreenStore.swift').read_text()
        self.assertIn('nativeWidth: display.screenWidth, nativeHeight: display.screenHeight',store)

if __name__=='__main__': unittest.main(verbosity=2)
