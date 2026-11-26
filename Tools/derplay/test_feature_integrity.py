"""Upstream entry inventory and real route guards; not device UI automation."""
import hashlib,json,re,plistlib,subprocess,sys,tempfile,unittest,zipfile
from pathlib import Path
from test_glass_ui import method
ROOT=Path(__file__).resolve().parents[2]
C=(ROOT/'App/ReceiverViewController.swift').read_text()
BASE=json.loads((ROOT/'DerPlay/UI_ENTRY_BASELINE.json').read_text())
def signatures(t):
    return set(re.sub(r'\s+',' ',x.split(' {')[0].rstrip(',]').rstrip()).strip() for x in re.findall(r'\.(?:control|field|page|action|externalLink|guide|view|note|info)\([^\n]+',t))
class IntegrityTests(unittest.TestCase):
    def test_upstream_rows(self):
        for name,record in BASE['files'].items():
            source=(ROOT/name).read_text(); current=signatures(source)
            for row in record['rows']:
                with self.subTest(file=name,row=row):
                    if row in current: continue
                    self.assertEqual(name,'App/ReceiverViewController.swift')
                    self.assertIn(row,BASE['approved_relocations'])
                    for token in BASE['approved_relocations'][row]['required_tokens']: self.assertIn(token,source)
        for t in ['.control(CWL("驾驶位")','.externalLink(CWL("反馈与建议")']: self.assertNotIn(t,C)
    def test_instrument_settings(self):
        order=re.search(r'static let menuOrder: \[Self\] = \[(.*?)\]',C).group(1)
        self.assertEqual(order.split(', '),['.airPlay','.browser','.carLife','.tailing','.ninebot43','.ninebot','.ninebotSeven','.zeeho','.zeehoSEPlus','.zeehoAE2','.cfmoto5','.cfmoto62'])
        for token in ['activeNinebotAddressField','cfmotoAddressField','activeZeehoAddressField','zeehoSEPlusFrameRateControl','zeehoSEPlusCanvasControl','zeehoSEPlusVideoModeControl','zeehoSEPlusAutomaticSwitch','zeeho62AutomaticSwitch']:
            self.assertIn(token,method(C,'headUnitPage'))
        for field in ['carLifeAddress','zeehoAddress','zeehoSEPlusAddress','cfmotoAddress','ninebotAddress','ninebot43Address','tailingAddress']:
            self.assertIn('forKey: "'+field+'"',method(C,'saveHeadUnitOutput'))
            self.assertIn(field+'Field.isEnabled = value',method(C,'setEditing'))
        for token in ['config.zeehoAutomaticAddress = usesAutomaticZeehoAddress','config.zeehoFrameRate = selectedZeehoFrameRate','config.zeehoVideoMode = selectedZeehoVideoMode','config.ninebotMode = mode','config.cfmotoProfile = profile']:
            self.assertIn(token,method(C,'configureDisplay'))
        self.assertIn('(outputMode == .zeeho || outputMode == .zeehoAE2) && zeeho62AutomaticSwitch.isOn',C)
        self.assertIn('targetIP.isEmpty && isZeeho',(ROOT/'App/TailingConnection.swift').read_text())
    def test_lifecycle_and_screen_routes(self):
        for name in ['zeehoFrameRateChanged','zeehoVideoSettingsChanged','zeehoAutomaticAddressChanged','httpsModeChanged','videoOutputToggled']:
            self.assertIn('!running, !waitingForNetwork',method(C,name))
        self.assertIn('followsCarScreen || outputMode == .carLife',method(C,'displayPage'))
        self.assertIn('CarScreenStore.lastCarLifeNegotiation()',method(C,'screensPage'))
        self.assertIn('CarScreenStore.clearCarLifeNegotiation()',method(C,'screensPage'))
        self.assertIn('CarScreenStore.recordCarLifeNegotiation(screen)',method(C,'toggleReceiver'))
        self.assertNotIn('按上报方向或竖屏',C)
        self.assertIn('waitingForNetwork || carLifeNegotiationTimeout != nil',method(C,'refreshDerPlayPanel'))
        for button in ['carLifeSettings','zeehoSettings','cfmotoSettings','ninebotSettings','tailingSettings']:
            self.assertIn(button+'.addAction(UIAction { [weak self] _ in self?.revealSettings(output: true)',C)
        for selector in ['toggleReceiver','copyVideoURL','copySecureVideoURL','toggleHTTPSAddress','showFullscreen']:
            self.assertIn('#selector('+selector+')',C)
        self.assertIn('func startPictureInPicture()', C)
        self.assertIn('self.updatePictureInPicturePolicy()', C)
    def test_update_entry_and_feed(self):
        for token in ['self.checkForUpdates()','self.showVersionHistory()']: self.assertIn(token,method(C,'aboutLinks'))
        self.assertIn('AppReleaseService().latest()',method(C,'checkForUpdates'))
        self.assertIn('VerifiedReleaseHistoryDetail',method(C,'showVersionHistory'))
        self.assertIn('navigation.pushViewController(controller, animated: true)',method(C,'presentReleaseController'))
        svc=(ROOT/'App/AppReleaseService.swift').read_text()
        self.assertIn('personroad/DerPlay',svc); self.assertNotIn('xmz28/CarWithin',svc)
    def test_manifest_producer(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); notes=p/'notes'; notes.write_text('test'); out=p/'ios-update.json'
            def generate(name,bundle,build):
                ipa=p/name
                with zipfile.ZipFile(ipa,'w') as z:
                    z.writestr('Payload/DerPlay.app/Info.plist',plistlib.dumps({'CFBundleIdentifier':bundle,'CFBundleShortVersionString':'0.0.1','CFBundleVersion':str(build),'MinimumOSVersion':'16.0'}))
                result=subprocess.run([sys.executable,str(ROOT/'Tools/make_ios_update.py'),str(ipa),'--notes',str(notes),'--output',str(out)],capture_output=True)
                return ipa,result
            for b in [9,10]:
                ipa,result=generate(f'DerPlay-0.0.1-build{b}.ipa','com.derplay.app',b); self.assertEqual(result.returncode,0,result.stderr)
                data=json.loads(out.read_text()); self.assertEqual(data['releaseTag'],f'v0.0.1-build{b}'); self.assertEqual(data['build'],b); self.assertEqual(data['sha256'],hashlib.sha256(ipa.read_bytes()).hexdigest()); self.assertEqual(data['size'],ipa.stat().st_size)
            for name,bundle in [('CarWithin.ipa','com.derplay.app'),('DerPlay-0.0.1-build10.ipa','com.carwithin.app')]:
                self.assertNotEqual(generate(name,bundle,10)[1].returncode,0)
