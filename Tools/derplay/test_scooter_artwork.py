import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
class ScooterArtworkTests(unittest.TestCase):
 def test_scoped_artwork_and_custom_priority(self):
  s=(ROOT/'App/ReceiverViewController.swift').read_text()
  for token in ['modeControl.selectedSegmentIndex == 1 && outputMode.usesInstrumentWiFi','icon: vehicleSettingsIcon','customVehicleIcon ?? defaultVehicleIcon()','usesScooterArtwork ? vehicleSettingsIcon : ("photo", .systemBlue)','UIImage(named: "DerPlayVehicleScooter")']:
   self.assertIn(token,s)
  self.assertTrue((ROOT/'App/Assets.xcassets/DerPlayVehicleScooter.imageset/icon.png').is_file())
  self.assertIn('symbol == "DerPlayVehicleScooter"',(ROOT/'App/SettingsUI.swift').read_text())

 def test_oem_asset_matches_wire_size_and_preserves_ui_artwork(self):
  import struct, json
  base=ROOT/'App/Assets.xcassets'
  oem=base/'DerPlayVehicleScooterOEM.imageset'
  self.assertEqual(json.loads((oem/'Contents.json').read_text())['images'], [{'filename':'icon.png','idiom':'universal'}])
  data=(oem/'icon.png').read_bytes()
  self.assertEqual(data[:16], b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR')
  self.assertEqual(struct.unpack('>IIBB',data[16:26]), (120,120,8,2))
  for name in ('DerPlayVehicleScooter','DerPlayVehicleScooterNight'):
   self.assertEqual(struct.unpack('>II',(base/(name+'.imageset')/'icon.png').read_bytes()[16:24]),(512,512))
  s=(ROOT/'App/ReceiverViewController.swift').read_text()
  body=s.split('private func defaultVehicleIcon(',1)[1].split('private func resumeLocalVideo',1)[0]
  self.assertLess(body.index('UIImage(named: "DerPlayVehicleScooterOEM")'),body.index('UIImage(named: "DerPlayVehicleScooter")'))
  self.assertIn('CGSize(width: 120, height: 120)',body)
  self.assertIn('format.scale = 1; format.opaque = true',body)
  self.assertIn('return UIGraphicsImageRenderer(size: size, format: format).pngData',body)
  self.assertIn('(1...192).contains(width)',(ROOT/'App/CarPlayInfo.swift').read_text())
