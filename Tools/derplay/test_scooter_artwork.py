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
