import unittest
from test_glass_ui import SETTINGS

class SettingsControlTests(unittest.TestCase):
    def test_choice_uses_plain_trigger_with_native_menu(self):
        choice = SETTINGS.split('final class ChoiceMenu:', 1)[1].split('final class StatusLabel:', 1)[0]
        self.assertNotIn('nativeButtonConfiguration()', choice)
        self.assertNotIn('configuration.cornerStyle = .capsule', choice)
        for token in ('UIButton.Configuration.plain()', 'button.showsMenuAsPrimaryAction = true', 'disabledItems.contains(index) ? .disabled : []', 'self.sendActions(for: .valueChanged)', 'button.isEnabled = isEnabled', 'state: index == selectedSegmentIndex ? .on : .off'):
            self.assertIn(token, choice)
    def test_inline_field_preserves_editing_and_accessibility(self):
        field = SETTINGS.split('static func field(', 1)[1].split('static func note(', 1)[0]
        for token in ('field.borderStyle = .none', 'field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)', 'field.clearButtonMode = .whileEditing', 'field.constraints.contains(where:', 'minimumHeight.identifier = "DerPlayInlineFieldMinimumHeight"', 'field.accessibilityLabel = title', 'field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)'):
            self.assertIn(token, field)
