"""Source guards, not a native View Area integration test."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[2]
class BrowserResizeTests(unittest.TestCase):
    def test_browser_report_does_not_restart(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        schedule=ui.split('private func scheduleScreenAdaptation() {',1)[1].split('private func adaptToPrimaryScreen()',1)[0]
        self.assertLess(schedule.index('guard outputMode != .browser else { return }'),schedule.index('DispatchWorkItem'))
        adapt=ui.split('private func adaptToPrimaryScreen() {',1)[1].split('private func browserStruggling',1)[0]
        self.assertLess(adapt.index('if outputMode == .browser || outputMode == .carLife { return }'),adapt.index('restartCarPlay('))
        self.assertIn('reportedScreen = display.map(CarScreenStore.recordCurrent)',ui)
    def test_existing_aspect_fit_and_touch_mapping(self):
        for f in ['App/BrowserReceiverPage.swift','App/Localization/Receiver.en.html']:
            with self.subTest(file=f):
                page=(ROOT/f).read_text()
                self.assertIn('object-fit:contain',page)
                self.assertIn('Math.min(r.width/vw,r.height/vh)',page)
                self.assertIn('sendDisplay,1500',page)
    def test_no_unverified_native_capability(self):
        info=(ROOT/'App/CarPlayInfo.swift').read_text()
        self.assertIn('"viewAreas": [view], "initialViewArea": 0',info)
if __name__=='__main__': unittest.main()

class ScreenHistoryIsolationTests(unittest.TestCase):
    def test_history_not_used_for_automatic_output(self):
        ui = (ROOT/'App/ReceiverViewController.swift').read_text()
        target = ui.split('private var targetScreen: CarScreen? {',1)[1].split('\n    }',1)[0]
        self.assertIn('return outputMode == .browser ? reportedScreen : nil', target)
        self.assertNotIn('CarScreenStore', target)
        callback = ui.split('private func browserReportedDisplay(',1)[1].split('\n    }',1)[0]
        self.assertIn('guard running, outputMode == .browser', callback)
        self.assertIn('display.map(CarScreenStore.recordCurrent)', callback)
        self.assertIn('reportedScreen = nil; primaryViewer = nil', ui)

class BrowserSessionIsolationTests(unittest.TestCase):
    def test_callbacks_capture_startup_identity(self):
        ui=(ROOT/'App/ReceiverViewController.swift').read_text()
        start=ui.split('localStartupID = startupID',1)[1].split('prepareExternalOutput(configuration: config)',1)[0]
        self.assertEqual(start.count('self.localStartupID == startupID'),4)
        self.assertIn('receiver.onBrowserGeometryFailure =',start)
        self.assertIn('self.running, self.outputMode == .browser',start)
        stop=ui.split('private func stop() {',1)[1]
        self.assertTrue(stop.lstrip().startswith('localStartupID = nil'))
        native=(ROOT/'App/NativeReceiver.swift').read_text()
        self.assertLess(native.index('let browserDisplay = onBrowserDisplay, browserStruggling = onBrowserStruggling'),native.index('queue.async',native.index('let listening = onListening')))
        self.assertIn('DispatchQueue.main.async { browserDisplay?(display, viewerID) }',native)
        self.assertIn('DispatchQueue.main.async { browserStruggling?(peer, reason) }',native)
        self.assertNotIn('self?.onBrowserDisplay?',native)
        self.assertNotIn('self?.onBrowserStruggling?',native)
    def test_server_installs_callbacks_after_old_session_stops(self):
        server=(ROOT/'App/VideoOutputServer.swift').read_text()
        start=server.split('private func startOnQueue(',1)[1].split('self.browserAudio = browserAudio',1)[0]
        self.assertLess(start.index('stopOnQueue()'),start.index('self.onDisplay = onDisplay; self.onStruggling = onStruggling'))
        stop=server.split('private func stopOnQueue()',1)[1].split('private func report(',1)[0]
        self.assertIn('onDisplay = nil; onStruggling = nil',stop)
        self.assertIn('self.clients[client.id] != nil',server)
