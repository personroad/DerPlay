"""Source-level regression guards for the persistent connection layer; not UIKit tests."""
import unittest
from test_glass_ui import GLASS, CONTROLLER, method

class ConnectionLayerTests(unittest.TestCase):
    def test_shared_geometry_is_frozen_through_interrupt(self):
        self.assertIn('motionGeometry ?? captureGeometry()', method(GLASS, 'render'))
        self.assertIn('($0.bounds.maxY-y)/$0.height', method(GLASS, 'interrupt'))
        self.assertIn('self.motionGeometry = nil', method(GLASS, 'setExpanded'))
        self.assertIn('motionGeometry?.height ?? effectiveHeight', method(GLASS, 'drag'))
    def test_panel_height_is_not_remeasured_during_session(self):
        body = method(CONTROLLER, 'prepareConnectionLayer')
        self.assertEqual(body.count('layer.panelHeight ='), 1)
        self.assertNotIn('navigation.onContentHeightChanged =', body)
    def test_navigation_slot_is_reserved_for_connection_only(self):
        self.assertIn('navigation.reservesConnectionPlayback = true', method(CONTROLLER, 'prepareConnectionLayer'))
        self.assertNotIn('reservesConnectionPlayback = true', method(CONTROLLER, 'revealSettings'))
        body = method(GLASS, 'clearTrailingPlaybackControls')
        self.assertIn('slot.width = 44', body)
        self.assertIn('if reservesConnectionPlayback', body)
    def test_tap_is_separate_from_animation_and_modal(self):
        body = method(CONTROLLER, 'connectionPlaybackTapped')
        for token in ['acceptsPlaybackTap == true', 'presentedViewController == nil', 'settingsNavigation?.presentedViewController == nil', 'toggleReceiver()']:
            self.assertIn(token, body)
        self.assertIn('animator == nil && !dragging', GLASS)
    def test_no_extra_playback_view(self):
        self.assertEqual(CONTROLLER.count('private let startButton = UIButton'), 1)
        layer = GLASS.split('final class ConnectionControlLayer:', 1)[1].split('final class DerPlayPreviewMark:', 1)[0]
        self.assertNotIn('UIButton(', layer)
        self.assertNotIn('CADisplayLink', layer)
        self.assertIn('addSubview(button)', layer)

    def test_only_owner_pan_can_mutate_or_finish_motion(self):
        body = method(GLASS, 'drag')
        self.assertIn('dragOwner = gesture', body)
        self.assertEqual(body.count('guard dragging, dragOwner === gesture else { return }'), 2)
        self.assertLess(body.index('dragOwner = nil'), body.index('dragging = false'))

    def test_external_transition_cannot_steal_active_drag(self):
        body = method(GLASS, 'setExpanded')
        self.assertLess(body.index('guard !dragging else { return }'), body.index('interrupt()'))

    def test_drag_resets_recognition_translation(self):
        body = method(GLASS, "drag")
        self.assertLess(body.index("dragStart = progress"), body.index("gesture.setTranslation(.zero, in: self)"))
        self.assertLess(body.index("gesture.setTranslation(.zero, in: self)"), body.index("case .changed:"))

    def test_real_navigation_slot_drives_endpoint(self):
        slot = method(GLASS, 'clearTrailingPlaybackControls')
        self.assertIn('UIBarButtonItem(customView: anchor)', slot)
        self.assertIn('anchor.isUserInteractionEnabled = false', slot)
        geometry = method(GLASS, 'captureGeometry')
        self.assertIn('slot.window === window', geometry)
        self.assertIn('slot.convert(slot.bounds, to: panel)', geometry)
        self.assertIn('panel.bounds.contains', geometry)
        self.assertIn('home: homeSlot.convert(homeSlot.bounds, to: self), end: end', geometry)

    def test_slot_lifecycle_and_geometry_freeze(self):
        prepare = method(CONTROLLER, 'prepareConnectionLayer')
        close = method(CONTROLLER, 'finishConnectionLayer')
        self.assertIn('[weak navigation] in navigation?.playbackSlot', prepare)
        self.assertIn('[weak layer] in layer?.setNeedsLayout()', prepare)
        self.assertIn('(navigation as? DerPlayGlassNavigationController)?.onPlaybackSlotChanged = nil', close)
        self.assertIn('connectionControlLayer?.playbackSlot = nil', close)
        expand = method(GLASS, 'setExpanded')
        self.assertLess(expand.index('preparePanelGeometry()'), expand.index('motionGeometry = captureGeometry()'))

    def test_settled_layout_measures_navigation_after_panel_layout(self):
        layer = GLASS.split('final class ConnectionControlLayer:', 1)[1]
        layout = method(layer, 'reconcileSettledLayout')
        self.assertLess(layout.index('preparePanelGeometry()'), layout.index('render(progress)'))
        finish = method(layer, 'setExpanded')
        self.assertLess(finish.index('self.progress = destination'), finish.index('self.preparePanelGeometry()'))
        self.assertLess(finish.index('self.preparePanelGeometry()'), finish.index('self.render(destination)'))

    def test_unchanged_playback_state_does_not_reconfigure_button(self):
        self.assertIn('if active != oldValue { updateButtonAppearance() }', GLASS)

    def test_playback_content_uses_shared_progress_without_threshold(self):
        layer = GLASS.split('final class ConnectionControlLayer:', 1)[1]
        self.assertIn('layoutPlaybackContent(progress)', method(layer, 'render'))
        body = method(layer, 'layoutPlaybackContent')
        self.assertIn('playbackTitle.alpha = 1 - p', body)
        self.assertIn('homeOffset * (1 - p)', body)
        self.assertIn('24 - 4 * p', body)
        self.assertNotIn('progress > 0.30', layer)
        self.assertIn('playbackContent.isUserInteractionEnabled = false', layer)
        self.assertIn('playbackContent.accessibilityElementsHidden = true', layer)

    def test_native_material_refresh_preserves_hidden_native_icon(self):
        self.assertIn('button.configuration?.imageColorTransformer = UIConfigurationColorTransformer { _ in .clear }', GLASS)
        self.assertIn('replacement.imageColorTransformer = previous.imageColorTransformer', method(CONTROLLER, 'refreshHomeButtonMaterials'))
        body = method(GLASS, 'updateButtonAppearance')
        self.assertIn('active ? "stop.fill" : "play.fill"', body)
        self.assertIn('button.accessibilityLabel', body)

    def test_navigation_slot_reused_on_repeated_will_show(self):
        body = method(GLASS, 'clearTrailingPlaybackControls')
        self.assertLess(body.index('if let existing'), body.index('let anchor = UIView'))
        self.assertIn('page.navigationItem.rightBarButtonItems = [existing] + items', body)

    def test_state_change_does_not_reset_foreground_during_animation(self):
        body = method(GLASS, 'updateButtonAppearance')
        self.assertIn('if animator == nil { layoutPlaybackContent(progress) }', body)
        self.assertIn('else { pendingLayout = true }', body)
        self.assertIn('self.render(destination)', method(GLASS, 'setExpanded'))

    def test_missing_geometry_rolls_back_before_animation_or_drag(self):
        expand = method(GLASS, 'setExpanded')
        rollback = expand.split('guard motionGeometry != nil else {', 1)[1].split('generation += 1', 1)[0]
        for token in ['targetOpen = false', 'progress = 0', 'panel.isHidden = true', 'backdrop.isHidden = true', 'accessibilityViewIsModal = false', 'onClosed?()']:
            self.assertIn(token, rollback)
        drag = method(GLASS, 'drag')
        self.assertLess(drag.index('guard motionGeometry != nil else'), drag.index('dragOwner = gesture'))
