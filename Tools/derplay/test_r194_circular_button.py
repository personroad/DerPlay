"""Source-level checks; actual iOS glass rendering requires device verification."""
import hashlib,json,unittest
from test_glass_ui import ROOT,GLASS,CONTROLLER,method
class R194CircularButton(unittest.TestCase):
    def test_square_intrinsic_size_and_layout(self):
        body=method(GLASS,'glassButton')
        self.assertIn('UIBarButtonItem(image: image, primaryAction: primaryAction)',body)
        self.assertIn('button.widthAnchor.constraint(equalToConstant: 44)',body)
        self.assertIn('button.heightAnchor.constraint(equalToConstant: 44)',body)
    def test_native_material_and_padding(self):
        for token in ['nativeButtonConfiguration(prominent: true) ?? .filled()', '.capsule','DerPlayGlassPalette.stopRed : DerPlayGlassPalette.startGreen','baseForegroundColor = .white']:
            self.assertIn(token,CONTROLLER)
        self.assertIn('width: 44, height: 44',method(GLASS,'captureGeometry'))
        self.assertIn('slot.hidesSharedBackground = true',method(GLASS,'clearTrailingPlaybackControls'))

    def test_general_hidden_before_button_creation(self):
        self.assertNotIn('glassButton(symbol: "xmark"',method(GLASS,'clearTrailingPlaybackControls'))
        self.assertNotIn('private func installPlayback(',GLASS)
    def test_prior_lock_and_other_runtime_digests_preserved(self):
        old=(ROOT/'DerPlay/R192-candidate-lock.json').read_bytes()
        prev=json.loads(old);new=json.loads((ROOT/'DerPlay/R194-candidate-lock.json').read_text())
        self.assertEqual(hashlib.sha256(old).hexdigest(),new['previous_lock_sha256'])
        self.assertEqual(prev['methods'],new['methods'])
        for name,entry in prev['files'].items():
            if name in ['App/DerPlayGlassUI.swift','App/ReceiverViewController.swift']:
                self.assertEqual(entry['candidate_sha256'],new['files'][name]['r192_sha256'])
                self.assertEqual(entry['r157_sha256'],new['files'][name]['r157_sha256'])
            else: self.assertEqual(entry,new['files'][name])
