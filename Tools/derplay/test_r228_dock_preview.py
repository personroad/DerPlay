"""R228 source and geometry contract, not UIKit/SwiftUI rendering."""
import unittest,json
import candidate_lock as guard
from test_glass_ui import GLASS,CONTROLLER,method
class DockPreviewTests(unittest.TestCase):
    def test_full_artwork_and_shared_outer_height(self):
        s=GLASS.split('struct DerPlayAppearancePreview: View',1)[1]
        self.assertIn('.frame(width: width, height: height)',s)
        self.assertIn('dashboard(width: width, height: height - barHeight)',s)
        self.assertIn('dashboard(width: width - barWidth, height: height)',s)
        self.assertIn('multiplier: 0.36',method(CONTROLLER,'dockPositionPage'))
    def test_compact_bottom_and_order(self):
        s=GLASS.split('struct DerPlayAppearancePreview: View',1)[1]
        self.assertIn('if horizontal { launcher } else { clock }',s)
        self.assertIn('if horizontal { clock } else { launcher }',s)
        self.assertIn('min(22, max(16, width * 0.06))',s)
        self.assertIn('min(16, barHeight - 4)',s)
    def test_protection_scope(self):
        p=guard.ROOT/'DerPlay/R227-candidate-lock.json'; old=json.loads(p.read_text()); new=json.loads((guard.ROOT/'DerPlay/R228-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),new['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],new['methods'])
        self.assertEqual(old['additional_geometry_files'],new['additional_geometry_files'])
        self.assertEqual(set(old['files']),set(new['files']))
        self.assertEqual({n for n in old['files'] if old['files'][n]!=new['files'][n]}, {'App/DerPlayGlassUI.swift'})
