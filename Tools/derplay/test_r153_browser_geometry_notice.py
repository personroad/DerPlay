"""R153: run the actual browser geometry predicate and notice code in Node."""
import pathlib, subprocess, unittest, shutil
ROOT=pathlib.Path(__file__).resolve().parents[2]
PAGES=['App/BrowserReceiverPage.swift','App/Localization/Receiver.en.html']
class BrowserGeometryNoticeTests(unittest.TestCase):
    def test_bilingual_fullscreen_reporting_and_safe_rendering(self):
        for path in PAGES:
            page=(ROOT/path).read_text()
            self.assertIn('object-fit:contain',page)
            self.assertIn('resizeTimer=setTimeout(sendDisplay,300)',page)
            self.assertIn('resizeTimer=setTimeout(sendDisplay,1500)',page)
            self.assertIn('id="geometryNotice" class="badge" role="status" hidden',page)
            self.assertIn("$('#geometryNotice').hidden=true;",page)
            self.assertIn('if(changed)updateGeometryNotice()',page)
    @unittest.skipUnless(shutil.which('node'),'Node unavailable')
    def test_actual_js_geometry_and_notice(self):
        for path in PAGES:
            page=(ROOT/path).read_text()
            js='function geometryMismatch('+page.split('function geometryMismatch(',1)[1].split("video.addEventListener('resize',updateGeometryNotice);",1)[0]
            script=js+'''
const assert=require('node:assert/strict');
assert.equal(geometryMismatch(900,1900,606,1280,900,1900,true),false);
assert.equal(geometryMismatch(1900,900,606,1280,1900,900,true),true);
assert.equal(geometryMismatch(900,1900,1280,720,900,1900,false),true);
assert.equal(geometryMismatch(900,1700,1280,720,900,1900,false),false);
assert.equal(geometryMismatch(0,1900,1280,720,900,1900,true),false);
assert.equal(geometryMismatch(900,1900,0,720,900,1900,true),false);
let shown=false,useWebCodecs=false,innerWidth=1900,innerHeight=900;
let view={width:606,height:1280},video={videoWidth:606,videoHeight:1280};
let screen={width:1900,height:900},notice={hidden:true};
const $=()=>notice,isFullscreen=()=>true;
updateGeometryNotice();assert.equal(notice.hidden,true);
shown=true;updateGeometryNotice();assert.equal(notice.hidden,false);
innerWidth=900;innerHeight=1900;updateGeometryNotice();assert.equal(notice.hidden,true);
useWebCodecs=true;innerWidth=1900;innerHeight=900;updateGeometryNotice();assert.equal(notice.hidden,false);
view={width:1280,height:606};updateGeometryNotice();assert.equal(notice.hidden,true);
'''
            subprocess.run(['node','-e',script],check=True,capture_output=True,text=True)
if __name__=='__main__': unittest.main()
