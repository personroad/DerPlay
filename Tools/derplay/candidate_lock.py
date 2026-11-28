"""R222 candidate integrity overlay; not a device or release acceptance result."""
import hashlib, json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
LOCK = json.loads((ROOT / 'DerPlay/R222-candidate-lock.json').read_text())
FILES = frozenset(['App/BrowserReceiverPage.swift', 'App/CarPlayAudio.swift', 'App/CarPlayMediaSession.swift', 'App/DerPlayGlassUI.swift', 'App/Localization/Localizable.xcstrings', 'App/Localization/Receiver.en.html', 'App/NativeReceiver.swift', 'App/ReceiverConfiguration.swift', 'App/ReceiverViewController.swift', 'App/SettingsUI.swift', 'App/VideoOutputServer.swift'])
METHODS = frozenset(['appearanceChanged', 'commitStartupSettings', 'configureDisplay', 'configureSettingsControls', 'derPlayIdentityPage', 'loadIdentity', 'stop', 'toggleReceiver', 'updatePictureInPicturePolicy'])

def digest(data):
    return hashlib.sha256(data).hexdigest()

def check_file(test, name, historical_digest):
    entry = LOCK['files'][name]
    test.assertEqual(entry['r157_sha256'], historical_digest)
    test.assertEqual(digest((ROOT / name).read_bytes()), entry['candidate_sha256'])

def check_method(test, name, controller, extract):
    entry = LOCK['methods'][name]
    if entry['candidate_sha256'] is None:
        test.assertEqual(name, 'appearanceChanged')
        test.assertNotRegex(controller, r'\bfunc\s+appearanceChanged\s*\(')
        test.assertNotIn('#selector(appearanceChanged)', controller)
    else:
        test.assertEqual(digest(extract(controller, name).encode()), entry['candidate_sha256'])
