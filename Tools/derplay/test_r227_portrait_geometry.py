"""R227: source scope and portrait geometry; Swift smoke covers executable math."""
import json, unittest, hashlib
from pathlib import Path
import candidate_lock as guard
from test_glass_ui import CONTROLLER
ROOT=guard.ROOT
class PortraitGeometryTests(unittest.TestCase):
    def test_automatic_preserves_report_and_explicit_compatibility_remains(self):
        s=(ROOT/'App/DerPlayCarLifeDisplay.swift').read_text()
        self.assertIn('case .automatic, .reported: return (width, height)',s)
        self.assertIn('case .landscape: return (max(width, height), min(width, height))',s)
        self.assertIn('case .portrait: return (min(width, height), max(width, height))',s)
        self.assertIn('private var carLifeDirection: DerPlayCarLifeDisplay.Direction { .automatic }',CONTROLLER)
        self.assertNotIn('case .automatic, .landscape:',s)
    def test_portrait_menu_has_reciprocals_and_common_phone_ratios(self):
        import re
        s=(ROOT/'App/ReceiverConfiguration.swift').read_text().split('static let aspectRatios = [',1)[1].split(']',1)[0]
        values={tuple(map(int,x)) for x in re.findall(r'width: (\d+), height: (\d+)',s)}
        self.assertTrue(all((h,w) in values for w,h in values if w>h))
        self.assertTrue({(9,20),(6,13),(3,5),(9,21),(10,16),(2,3)} <= values)
    def test_protection_scope(self):
        p=ROOT/'DerPlay/R226-candidate-lock.json'; old=json.loads(p.read_text())
        lock=json.loads((ROOT/'DerPlay/R227-candidate-lock.json').read_text())
        self.assertEqual(guard.digest(p.read_bytes()),lock['immediate_parent_lock_sha256'])
        self.assertEqual(old['methods'],lock['methods'])
        self.assertEqual(set(old['files']),set(lock['files']))
        self.assertEqual({n for n in old['files'] if old['files'][n]!=lock['files'][n]}, {'App/ReceiverViewController.swift','App/ReceiverConfiguration.swift'})
        self.assertEqual(set(lock['additional_geometry_files']),{'App/DerPlayCarLifeDisplay.swift'})
        for n,e in guard.LOCK['additional_geometry_files'].items():
            self.assertEqual(hashlib.sha256((ROOT/n).read_bytes()).hexdigest(),e['candidate_sha256'])
