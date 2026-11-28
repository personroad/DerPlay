"""R229 scope checks; executable geometry smoke runs separately."""
import json,unittest
import candidate_lock as guard
class RasterAlignmentTests(unittest.TestCase):
    def test_scope(self):
        p=guard.ROOT/'DerPlay/R228-candidate-lock.json'
        old=json.loads(p.read_text()); new=json.loads((guard.ROOT/'DerPlay/R229-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),new['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],new['methods'])
        self.assertEqual(old['files'],new['files'])
        n='App/DerPlayCarLifeDisplay.swift'
        self.assertEqual(old['additional_geometry_files'][n]['candidate_sha256'],new['additional_geometry_files'][n]['r228_sha256'])
        self.assertEqual(guard.digest((guard.ROOT/n).read_bytes()),new['additional_geometry_files'][n]['candidate_sha256'])
    def test_bounds(self):
        s=(guard.ROOT/'App/DerPlayCarLifeDisplay.swift').read_text()
        self.assertEqual(s.count('let w = alignedWidth(height: h, aspect: aspect, area: area)'),2)
        self.assertIn('min(1920, area / height) / 2 * 2',s)
        self.assertIn('width.isMultiple(of: 2)',s)
        self.assertIn('height.isMultiple(of: 2)',s)
