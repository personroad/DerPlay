import Foundation

@main struct DisplayGeometrySmoke {
    static func main() {
        func fit(_ rw: Int, _ rh: Int, _ mw: Int, _ mh: Int) -> DisplayGeometry.Fit {
            guard let value = DisplayGeometry.fit(ratioWidth: rw, ratioHeight: rh, maxWidth: mw, maxHeight: mh) else {
                fatalError("No valid fit for \(rw):\(rh) in \(mw)x\(mh)")
            }
            return value
        }
        precondition(DisplayGeometry.orientedBounds(width: 1280, height: 720, portrait: false) == .init(width: 1280, height: 720))
        precondition(DisplayGeometry.orientedBounds(width: 1280, height: 720, portrait: true) == .init(width: 720, height: 1280))
        precondition(fit(16, 9, 1280, 720).size == .init(width: 1280, height: 720))
        precondition(fit(4, 3, 1280, 720).size == .init(width: 960, height: 720))
        precondition(fit(9, 16, 720, 1280).size == .init(width: 720, height: 1280))
        precondition(fit(9, 19, 720, 1280).size == .init(width: 594, height: 1254))
        precondition(fit(3, 4, 720, 1280).size == .init(width: 720, height: 960))
        precondition(fit(4, 1, 1280, 720).size == .init(width: 1280, height: 320))
        precondition(fit(1, 4, 720, 1280).size == .init(width: 320, height: 1280))
        let tiers: [DisplayGeometry.Size] = [.init(width: 800, height: 480), .init(width: 1280, height: 720), .init(width: 1920, height: 1080)]
        precondition(DisplayGeometry.fit(ratioWidth: 1, ratioHeight: 5, maxWidth: 720, maxHeight: 1280) == nil)
        precondition(DisplayGeometry.fitPreservingRatio(ratioWidth: 32, ratioHeight: 9, landscapeBounds: tiers) == .init(size: .init(width: 1280, height: 360), adjustedForMinimumSide: true))
        precondition(DisplayGeometry.fitPreservingRatio(ratioWidth: 1, ratioHeight: 5, landscapeBounds: Array(tiers.dropFirst())) == .init(size: .init(width: 384, height: 1920), adjustedForMinimumSide: true))
        precondition(DisplayGeometry.fitPreservingRatio(ratioWidth: 1, ratioHeight: 20, landscapeBounds: tiers) == nil)
        precondition(DisplayGeometry.fitPreservingRatio(ratioWidth: 9, ratioHeight: 19, landscapeBounds: Array(tiers.dropFirst())) == .init(size: .init(width: 594, height: 1254), adjustedForMinimumSide: false))
        precondition([fit(32, 9, 3840, 2160), fit(9, 19, 720, 1280)].allSatisfy {
            $0.size.width % 2 == 0 && $0.size.height % 2 == 0 && $0.size.width >= 320 && $0.size.height >= 320
        })
        precondition(DisplayGeometry.fit(ratioWidth: 9, ratioHeight: 19, maxWidth: 300, maxHeight: 500) == nil)
        precondition(DisplayGeometry.reducedRatio(width: 900, height: 1900) == .init(width: 9, height: 19))
        precondition(DisplayGeometry.fillsScreen(viewportWidth: 900, viewportHeight: 1900, screenWidth: 900, screenHeight: 1900, fullscreen: false))
        precondition(DisplayGeometry.fillsScreen(viewportWidth: 900, viewportHeight: 1900, screenWidth: 900, screenHeight: 2000, fullscreen: false) == false)
        precondition(DisplayGeometry.fillsScreen(viewportWidth: 900, viewportHeight: 1800, screenWidth: 900, screenHeight: 1900, fullscreen: true))

        // R155: exact 9:19 within the pixel budget, including rotated equivalence.
        precondition(fit(19, 9, 1280, 720).size == .init(width: 1254, height: 594))
        precondition(fit(9, 19, 480, 800).size == .init(width: 378, height: 798))
        precondition(fit(9, 19, 1080, 1920).size == .init(width: 900, height: 1900))
        precondition(DisplayGeometry.fit(ratioWidth: 1, ratioHeight: 1, maxWidth: 400, maxHeight: 400, minimumShortSide: 16_385) == nil)
        // Large coprime dimensions cannot be exact at this tier. Check the
        // error and area against the old floor-aligned raster, plus rotation.
        for (rw, rh) in [(1001, 1901), (1081, 2281), (719, 1281), (999, 1000), (320, 1279), (9, 19), (16, 9)] {
            let portrait = rh > rw
            let mw = portrait ? 720 : 1280, mh = portrait ? 1280 : 720
            let result = fit(rw, rh, mw, mh).size
            let scale = min(Double(mw) / Double(rw), Double(mh) / Double(rh))
            let oldW = Int((Double(rw) * scale + 1e-8).rounded(.down)) / 2 * 2
            let oldH = Int((Double(rh) * scale + 1e-8).rounded(.down)) / 2 * 2
            let short = min(result.width, result.height), oldShort = min(oldW, oldH)
            let error = abs(result.width * rh - result.height * rw)
            let oldError = abs(oldW * rh - oldH * rw)
            precondition(error * oldShort <= oldError * short)
            precondition(result.width * result.height * 100 >= oldW * oldH * 95)
            precondition(result.width <= mw && result.height <= mh && short >= 320)
            precondition(result.width % 2 == 0 && result.height % 2 == 0)
            precondition(fit(rh, rw, mh, mw).size == .init(width: result.height, height: result.width))
        }

        // R156: browser and AirPlay rotate tier bounds; CarLife has fixed decoder axes.
        let carLifeCap = DisplayGeometry.Size(width: 1920, height: 1080)
        let fullTiers = tiers + [.init(width: 2560, height: 1440), .init(width: 3840, height: 2160)]
        var checked = 0
        for ceiling in [DisplayGeometry.Size(width: 3840, height: 2160), carLifeCap, .init(width: 1280, height: 720)] {
            for index in fullTiers.indices {
                let candidates = fullTiers[index...].map { DisplayGeometry.Size(width: min($0.width, ceiling.width), height: min($0.height, ceiling.height)) }
                for (rw, rh) in [(32,9),(21,9),(16,9),(16,10),(4,3),(4,1),(3,2),(3,1),(1,1),(9,16),(3,4),(9,19),(1,5),(1,20)] {
                    for fixed in [false, true] {
                        let cap = fixed ? carLifeCap : nil
                        if let result = DisplayGeometry.fitPreservingRatio(ratioWidth: rw, ratioHeight: rh, landscapeBounds: candidates, absoluteBounds: cap) {
                            let limit = DisplayGeometry.orientedBounds(width: ceiling.width, height: ceiling.height, portrait: rh > rw)
                            precondition(result.size.width <= limit.width && result.size.height <= limit.height)
                            if fixed { precondition(result.size.width <= 1920 && result.size.height <= 1080) }
                            precondition(min(result.size.width, result.size.height) >= 320)
                            precondition(result.size.width % 2 == 0 && result.size.height % 2 == 0)
                            precondition(abs(Double(result.size.width * rh) / Double(result.size.height * rw) - 1) < 0.01)
                        } else { precondition(rh > rw * 3 || rw > rh * 3) }
                        checked += 1
                    }
                }
            }
        }
        precondition(DisplayGeometry.fitPreservingRatio(ratioWidth: 9, ratioHeight: 19, landscapeBounds: tiers, absoluteBounds: carLifeCap) == .init(size: .init(width: 378, height: 798), adjustedForMinimumSide: false))
        precondition(DisplayGeometry.fitPreservingRatio(ratioWidth: 9, ratioHeight: 19, landscapeBounds: Array(tiers.dropFirst()), absoluteBounds: carLifeCap) == .init(size: .init(width: 504, height: 1064), adjustedForMinimumSide: false))
        print("R156 geometry matrix: \(checked) cases PASS")

        let base = [DisplayGeometry.Ratio(width: 32, height: 9), .init(width: 21, height: 9),
                    .init(width: 16, height: 9), .init(width: 16, height: 10), .init(width: 4, height: 3),
                    .init(width: 4, height: 1), .init(width: 3, height: 2), .init(width: 3, height: 1),
                    .init(width: 1, height: 1), .init(width: 9, height: 16), .init(width: 3, height: 4)]
        let ordered = DisplayGeometry.orderedRatios(builtIn: base,
            discovered: [.init(width: 8, height: 3), DisplayGeometry.reducedRatio(width: 900, height: 1900)!, .init(width: 9, height: 19)])
        precondition(ordered.map(\.title) == ["32:9", "21:9", "16:9", "16:10", "8:3", "4:3", "4:1", "3:2", "3:1", "1:1", "9:16", "9:19", "3:4"])
        print("DisplayGeometrySmoke PASS: rotated bounds, hard caps, 320px minimum, even pixels, exact/approximate ratio optimization, rotation, area budget, reduced and ordered device ratios")
    }
}
