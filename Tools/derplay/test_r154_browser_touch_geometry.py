"""Execute both actual browser input handlers against simulated DOM geometry."""
import pathlib, shutil, subprocess, unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
PAGES=['App/BrowserReceiverPage.swift','App/Localization/Receiver.en.html']
class BrowserTouchGeometryTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('node'),'Node unavailable')
    def test_actual_pointer_handlers(self):
        for path in PAGES:
            with self.subTest(path=path):
                page=(ROOT/path).read_text()
                js=page.split('// ---------- input ----------',1)[1].split("document.addEventListener('mousemove'",1)[0]
                setup='''const assert=require('node:assert/strict');
let shown=false,useWebCodecs=false,hold={hidden:true},document={hidden:false},ws={readyState:1};
let rect={left:0,top:0,width:1900,height:900};
let video={videoWidth:606,videoHeight:1280,getBoundingClientRect:()=>rect};
let view={width:606,height:1280,getBoundingClientRect:()=>rect};
let events={},sent=[],showTouches=false;
const touchLayer={addEventListener:(n,f)=>events[n]=f,setPointerCapture(){},releasePointerCapture(){}};
const send=o=>sent.push(o),wake=()=>{};
const event=(id,x,y)=>({pointerId:id,clientX:x,clientY:y,preventDefault(){}});
'''
                checks='''
events.pointerdown(event(1,950,450));assert.equal(sent.length,0);
shown=true;events.pointerdown(event(1,100,450));assert.equal(sent.length,0);
events.pointerdown(event(1,950,450));assert.equal(sent.at(-1).points[0].x,0.5);assert.equal(sent.at(-1).points[0].y,0.5);
events.pointerdown(event(2,1000,500));assert.equal(sent.at(-1).points.length,2);
rect={left:0,top:0,width:900,height:1900};events.pointermove(event(1,450,950));assert.deepEqual(sent.at(-1).points,[]);assert.equal(fingers.size,0);
events.pointerup(event(2,1000,500));assert.equal(fingers.size,0);
useWebCodecs=true;events.pointerdown(event(3,450,950));assert.equal(sent.at(-1).points[0].x,0.5);
view.width=1280;view.height=720;events.pointermove(event(3,450,950));assert.deepEqual(sent.at(-1).points,[]);
hold.hidden=false;events.pointerdown(event(4,450,950));assert.equal(fingers.size,0);
hold.hidden=true;view.width=0;assert.equal(picture(),null);
view.width=1280;events.pointerdown(event(5,450,950));events.pointermove(event(5,-100,950));assert.equal(sent.at(-1).points[0].x,0);events.pointerup(event(5,0,950));assert.deepEqual(sent.at(-1).points,[]);
'''
                subprocess.run(['node','-e',setup+js+checks],check=True,capture_output=True,text=True)
    def test_lifecycle_hooks(self):
        for path in PAGES:
            page=(ROOT/path).read_text()
            self.assertIn('function teardown(){\n cancelFingers();',page)
            self.assertIn('if(changed){cancelFingers();view.width=',page)
            self.assertIn("document.addEventListener('fullscreenchange',cancelFingers)",page)
            self.assertIn("window.addEventListener('blur',cancelFingers)",page)
            self.assertIn('if(document.hidden)cancelFingers()',page)
