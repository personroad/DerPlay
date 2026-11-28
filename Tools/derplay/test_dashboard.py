#!/usr/bin/env python3
"""Source-level regression guard, not an Auto Layout or device test."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

def check_dashboard(controller, surface):
    checks = {
        'removed device status heading': '设备状态' not in controller,
        'fixed footer': 'footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)' in controller,
        'scroll ends above footer': 'scroll.bottomAnchor.constraint(equalTo: footer.topAnchor)' in controller,
        'primary button in footer': 'footer.addSubview(playbackHomeSlot)' in controller and 'ConnectionControlLayer(button: startButton, homeSlot: playbackHomeSlot)' in controller and not re.search(r'stack\.addArrangedSubview\(startButton\)', controller),
        'minimum button height': 'playbackHomeSlot.heightAnchor.constraint(equalToConstant: 80)' in controller,
        'preview at top': all(f'stack.insertArrangedSubview({name}, at: 0)' in controller for name in ('inlineVideoShadow', 'derPlayPreviewPlaceholder')),
        'preserve video aspect': bool(re.search(r'display\.videoGravity\s*=\s*\.resizeAspect\b', surface)) and 'multiplier: displayAspectHeight' in controller,
        'actual video hides placeholder': 'derPlayPreviewPlaceholder.isHidden = displayedVideo' in controller,
        'upstream menu retained': 'HeadUnitOutput.menuOrder.map' in controller,
        'extensions retained': 'DerPlayUpstreamBridge.extensionMenuItems()' in controller,
        'no external controls': not re.search(r'stack\.(?:insert|add)ArrangedSubview\((?:videoActions|controlBar)', controller),
        'fullscreen overlay': all(token in controller for token in ('inlineVideoContainer.addSubview(fullscreenButton)', 'fullscreenButton.trailingAnchor.constraint(equalTo: inlineVideoContainer.trailingAnchor', 'fullscreenButton.widthAnchor.constraint(equalToConstant: 44)', 'fullscreenButton.heightAnchor.constraint(equalToConstant: 44)', 'action: #selector(showFullscreen)')),
        'underlying controls retained': ' [.home, .back, .siri, .previous, .playPause, .next, .hookSwitch]' in controller and 'self?.receiver.press(control)' in controller and 'func startPictureInPicture()' in controller,
        'overlay lifecycle': all(token in controller for token in ('hideFullscreen(); hidePreviewFullscreenButton()', 'self.hidePreviewFullscreenButton()', 'self?.refreshPreviewFullscreenButton()', 'fullscreenButton.isHidden = true', 'fullscreenButton.isHidden = false', 'Timer(timeInterval: 3, repeats: false)', 'previewFullscreenTimer?.invalidate()')),
        'touch forwarding preserved': 'self?.receiver.touches(source: "local", points)' in controller and 'guard displayedVideo, fullscreenContainer == nil else { return }' in controller,
        'fullscreen exit always reachable': '        addFullscreenExitButton(to: container)' in controller and 'exit.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor' in controller,
        'primary action wired': 'action: #selector(connectionPlaybackTapped)' in controller and 'toggleReceiver()' in controller.split('func connectionPlaybackTapped()', 1)[1].split('@objc', 1)[0],
    }
    return [name for name, ok in checks.items() if not ok]

class DashboardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controller = (ROOT/'App/ReceiverViewController.swift').read_text()
        cls.surface = (ROOT/'App/H264Surface.swift').read_text()
    def test_current_source(self):
        self.assertEqual(check_dashboard(self.controller, self.surface), [])
    def test_detect_reintroduced_status(self):
        self.assertIn('removed device status heading', check_dashboard(self.controller+'\n// 设备状态', self.surface))
    def test_detect_footer_regression(self):
        self.assertIn('fixed footer', check_dashboard(self.controller.replace('footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)', ''), self.surface))
    def test_detect_crop(self):
        self.assertIn('preserve video aspect', check_dashboard(self.controller, self.surface.replace('.resizeAspect', '.resizeAspectFill')))
    def test_detect_missing_menu(self):
        self.assertIn('upstream menu retained', check_dashboard(self.controller.replace('HeadUnitOutput.menuOrder.map', '[] .map'), self.surface))

    def test_detect_action_relocation(self):
        broken = self.controller + '\nstack.addArrangedSubview(controlBar)'
        self.assertIn('no external controls', check_dashboard(broken, self.surface))
    def test_detect_missing_control(self):
        self.assertIn('underlying controls retained', check_dashboard(self.controller.replace('.previous, .playPause, .next', '.previous, .next'), self.surface))
    def test_detect_lifecycle_regression(self):
        self.assertIn('overlay lifecycle', check_dashboard(self.controller.replace('self?.refreshPreviewFullscreenButton()', ''), self.surface))
    def test_detect_missing_overlay(self):
        self.assertIn('fullscreen overlay', check_dashboard(self.controller.replace('inlineVideoContainer.addSubview(fullscreenButton)', ''), self.surface))
    def test_detect_missing_touch_forwarding(self):
        self.assertIn('touch forwarding preserved', check_dashboard(self.controller.replace('self?.receiver.touches(source: "local", points)', ''), self.surface))
    def test_detect_missing_exit(self):
        self.assertIn('fullscreen exit always reachable', check_dashboard(self.controller.replace('        addFullscreenExitButton(to: container)', ''), self.surface))

if __name__ == '__main__': unittest.main(verbosity=2)
