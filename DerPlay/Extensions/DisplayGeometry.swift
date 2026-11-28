// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Pure display geometry shared by the app and offline regression tests.
/// A clarity tier supplies independent width/height bounds; it is not a fixed raster.
enum DisplayGeometry {
    struct Size: Equatable {
        let width: Int
        let height: Int
        var isPortrait: Bool { height > width }
    }

    struct Ratio: Equatable {
        let width: Int
        let height: Int
        var title: String { "\(width):\(height)" }
    }

    struct Fit: Equatable {
        let size: Size
        let adjustedForMinimumSide: Bool
    }

    /// Fit an even raster with minimum relative ratio error within a bounded area loss.
    /// A tier that cannot meet the minimum is rejected, never stretched.
    static func fit(ratioWidth: Int, ratioHeight: Int, maxWidth: Int, maxHeight: Int,
                    minimumShortSide: Int = 320) -> Fit? {
        guard (1...16_384).contains(ratioWidth), (1...16_384).contains(ratioHeight),
              minimumShortSide > 0, minimumShortSide <= 16_384, (minimumShortSide...16_384).contains(maxWidth),
              (minimumShortSide...16_384).contains(maxHeight) else { return nil }
        // Work in long/short coordinates so rotating the screen produces the same raster rotated.
        let portrait = ratioHeight > ratioWidth
        let longRatio = portrait ? ratioHeight : ratioWidth
        let shortRatio = portrait ? ratioWidth : ratioHeight
        let longBound = evenFloor(portrait ? maxHeight : maxWidth)
        let shortBound = evenFloor(portrait ? maxWidth : maxHeight)
        let maxLong = min(longBound, evenFloor(shortBound * longRatio / shortRatio))
        let baseShort = evenFloor(maxLong * shortRatio / longRatio)
        guard baseShort >= minimumShortSide else { return nil }
        let baseArea = maxLong * baseShort
        // Preserve at least 95% of the maximum floor-aligned raster area. Within
        // that budget minimize relative aspect error, then maximize pixel count.
        var bestLong = maxLong, bestShort = baseShort
        var bestError = abs(maxLong * shortRatio - baseShort * longRatio)
        for long in stride(from: maxLong, through: minimumShortSide, by: -2) {
            if long * shortBound * 100 < baseArea * 95 { break }
            let floorShort = evenFloor(long * shortRatio / longRatio)
            for short in [floorShort, floorShort + 2] {
                guard short >= minimumShortSide, short <= shortBound, short <= long,
                      long * short * 100 >= baseArea * 95 else { continue }
                let error = abs(long * shortRatio - short * longRatio)
                // Compare error / short without floating point; all operands are bounded.
                let lhs = Int64(error) * Int64(bestShort)
                let rhs = Int64(bestError) * Int64(short)
                if lhs < rhs || (lhs == rhs && long * short > bestLong * bestShort) {
                    bestLong = long; bestShort = short; bestError = error
                }
            }
            if bestError == 0 { break } // later long edges cannot improve exact-ratio area
        }
        let size = portrait ? Size(width: bestShort, height: bestLong) : Size(width: bestLong, height: bestShort)
        return Fit(size: size, adjustedForMinimumSide: false)
    }

    /// First candidate is the requested tier; subsequent candidates are higher tiers
    /// already clamped to the protocol and performance ceilings.
    static func fitPreservingRatio(ratioWidth: Int, ratioHeight: Int, landscapeBounds: [Size], absoluteBounds: Size? = nil) -> Fit? {
        for (index, candidate) in landscapeBounds.enumerated() {
            let oriented = orientedBounds(width: candidate.width, height: candidate.height, portrait: ratioHeight > ratioWidth)
            // Some decoders have fixed axis limits, independent of screen orientation.
            let bounds = absoluteBounds.map { Size(width: min(oriented.width, $0.width), height: min(oriented.height, $0.height)) } ?? oriented
            if let result = fit(ratioWidth: ratioWidth, ratioHeight: ratioHeight, maxWidth: bounds.width, maxHeight: bounds.height) {
                return Fit(size: result.size, adjustedForMinimumSide: index > 0)
            }
        }
        return nil
    }

    /// Rotate a landscape clarity tier's bounds for portrait output.
    static func orientedBounds(width: Int, height: Int, portrait: Bool) -> Size {
        portrait ? Size(width: height, height: width) : Size(width: width, height: height)
    }

    static func fillsScreen(viewportWidth: Int, viewportHeight: Int, screenWidth: Int?, screenHeight: Int?,
                            fullscreen: Bool, coverageTolerance: Double = 0.03) -> Bool {
        if fullscreen { return true }
        guard let screenWidth, let screenHeight, screenWidth > 0, screenHeight > 0,
              viewportWidth > 0, viewportHeight > 0, coverageTolerance >= 0 else { return false }
        let range = (1 - coverageTolerance)...(1 + coverageTolerance)
        return range.contains(Double(viewportWidth) / Double(screenWidth))
            && range.contains(Double(viewportHeight) / Double(screenHeight))
    }

    static func reducedRatio(width: Int, height: Int) -> Ratio? {
        guard (160...16_384).contains(width), (160...16_384).contains(height) else { return nil }
        let divisor = gcd(width, height)
        guard divisor > 0 else { return nil }
        return Ratio(width: width / divisor, height: height / divisor)
    }

    /// Stable order: landscape, square, portrait; within each group sort by the
    /// first (width) number descending. Existing items win exact-ratio duplicates.
    static func orderedRatios(builtIn: [Ratio], discovered: [Ratio]) -> [Ratio] {
        var values = builtIn
        for ratio in discovered where ratio.width > 0 && ratio.height > 0 {
            if !values.contains(where: { $0.width * ratio.height == ratio.width * $0.height }) {
                values.append(ratio)
            }
        }
        return values.enumerated().sorted { lhs, rhs in
            let leftGroup = group(lhs.element), rightGroup = group(rhs.element)
            if leftGroup != rightGroup { return leftGroup < rightGroup }
            if lhs.element.width != rhs.element.width { return lhs.element.width > rhs.element.width }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private static func group(_ ratio: Ratio) -> Int {
        if ratio.width > ratio.height { return 0 }
        if ratio.width == ratio.height { return 1 }
        return 2
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var x = a, y = b
        while y != 0 { let remainder = x % y; x = y; y = remainder }
        return x
    }

    private static func evenFloor(_ value: Int) -> Int { max(0, value / 2 * 2) }
}
