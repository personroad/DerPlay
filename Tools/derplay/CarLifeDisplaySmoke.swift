import Foundation
@main struct Smoke {
    static func main() {
        for (w,h) in [(1280,720),(2340,1080),(2400,1080),(1920,720),(1024,600),(2560,1440),(2560,720),(1920,320)] {
            let size = DerPlayCarLifeDisplay.size(width: w, height: h, area: 1920*1080)!
            precondition(size.width % 2 == 0 && size.height % 2 == 0)
            precondition(size.width <= 1920 && size.height <= 1080)
            precondition(abs(Double(size.width)*Double(h)/(Double(size.height)*Double(w))-1) < 0.01)
        }
        let s = DerPlayCarLifeDisplay.size(width: 2340,height:1080,area:1280*720)!
        precondition(s.width*s.height <= 1280*720)
        precondition(DerPlayCarLifeDisplay.needsAdaptation(width:s.width,height:s.height,liveWidth:1280,liveHeight:720))
        precondition(!DerPlayCarLifeDisplay.needsAdaptation(width:1920,height:1080,liveWidth:1280,liveHeight:720))
        precondition(!DerPlayCarLifeDisplay.accepts(width:0,height:1080))
        precondition(DerPlayCarLifeDisplay.accepts(width:1080,height:1920))
        let portraitReport = DerPlayCarLifeDisplay.size(width:1080,height:2210,area:1280*720)!
        let landscapeReport = DerPlayCarLifeDisplay.size(width:2210,height:1080,area:1280*720)!
        precondition(portraitReport.width == landscapeReport.width && portraitReport.height == landscapeReport.height)
        precondition(abs(Double(portraitReport.width)*1080/(Double(portraitReport.height)*2210)-1) < 0.01)
        precondition(portraitReport.width*portraitReport.height <= 1280*720)
        precondition(!DerPlayCarLifeDisplay.needsAdaptation(width:1080,height:2210,liveWidth:portraitReport.width,liveHeight:portraitReport.height))
        precondition(DerPlayCarLifeDisplay.needsAdaptation(width:1080,height:2210,liveWidth:1280,liveHeight:720))
        print("1080×2210 -> \(portraitReport.width)×\(portraitReport.height)")
        precondition(DerPlayCarLifeDisplay.size(width:1920,height:320,area:1000) == nil)
        // Real negotiation helper: no raster until first valid report, immutable after reply.
        var startup = DerPlayCarLifeDisplay.Negotiation(area: 1280*720)
        precondition(startup.raster == nil)
        precondition(startup.selection(width: 0, height: 1080) == nil)
        precondition(startup.raster == nil)
        let first = startup.selection(width: 1080, height: 2210)!
        precondition(first.width == portraitReport.width && first.height == portraitReport.height)
        precondition(startup.raster == nil) // selection alone is not a successful reply
        precondition(startup.commit(width: first.width, height: first.height))
        for (w,h) in [(2340,1080), (1280,720), (1920,720)] {
            let later = startup.selection(width: w, height: h)!
            precondition(later.width == first.width && later.height == first.height)
            precondition(!startup.commit(width: later.width, height: later.height))
        }
        let fresh = DerPlayCarLifeDisplay.Negotiation(area: 1280*720)
        precondition(fresh.raster == nil)
        precondition(fresh.selection(width: 1280, height: 720)!.width == 1280)
        for (w,h) in [(1024,768),(1920,1080),(2520,1080),(3840,1080),(5760,1080),(1080,1080),(1080,1920),(1080,2210),(768,1024)] {
            for direction in [DerPlayCarLifeDisplay.Direction.reported, .landscape, .portrait, .automatic] {
                let ref = direction.reference(width: w, height: h)
                if let result = DerPlayCarLifeDisplay.size(width: w, height: h, area: 1920*1080, direction: direction) {
                    precondition(result.width >= 320 && result.height >= 320)
                    precondition(result.width <= 1920 && result.height <= 1080)
                    precondition(result.width * result.height <= 1920*1080)
                    precondition(abs(Double(result.width)*Double(ref.height)/(Double(result.height)*Double(ref.width))-1) < 0.01)
                } else {
                    // Very tall canvases cannot satisfy the conservative decoder height cap.
                    precondition(Double(ref.width)/Double(ref.height) < 320.0/1080.0)
                }
            }
        }
        let vertical = DerPlayCarLifeDisplay.size(width:1080,height:2210,area:1280*720,direction:.reported)!
        precondition(vertical.width < vertical.height)
        precondition(!DerPlayCarLifeDisplay.needsAdaptation(width:1080,height:2210,liveWidth:vertical.width,liveHeight:vertical.height,direction:.reported))
        var verticalStartup = DerPlayCarLifeDisplay.Negotiation(area:1280*720,direction:.portrait)
        let v = verticalStartup.selection(width:2210,height:1080)!
        precondition(v.width == vertical.width && v.height == vertical.height)
        precondition(verticalStartup.commit(width:v.width,height:v.height))
        precondition(verticalStartup.selection(width:1920,height:1080)!.width == v.width)
        print("Portrait 1080×2210 -> \(vertical.width)×\(vertical.height)")
        print("CarLife display smoke PASS (ratio, limits, alignment, invalid input, first reply locks raster)")
    }
}
