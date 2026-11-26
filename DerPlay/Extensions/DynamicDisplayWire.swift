// SPDX-License-Identifier: GPL-3.0-or-later
// Protocol reference: DiPlay (https://github.com/shihabal3amri/DiPlay),
// AirPlayInfoPlist.kt and AirPlaySession.kt, GPL-3.0. Swift implementation for DerPlay.
import Foundation

/// Offline, validated wire payload construction. Not enabled in the receiver until
/// event response correlation, rendering confirmation and touch mapping are integrated.
struct DynamicDisplayWire {
    struct Region: Equatable {
        let x: Int, y: Int, width: Int, height: Int
    }
    let width: Int, height: Int
    let regions: [Region]
    let displayUUID: String

    init?(width: Int, height: Int, displayUUID: String, regions: [Region]) {
        guard (1...16384).contains(width), (1...16384).contains(height),
              UUID(uuidString: displayUUID) != nil, (2...16).contains(regions.count),
              regions.first == Region(x: 0, y: 0, width: width, height: height),
              regions.allSatisfy({ r in
                  r.x >= 0 && r.y >= 0 && r.width > 0 && r.height > 0 &&
                  r.width <= width && r.height <= height && r.x <= width - r.width && r.y <= height - r.height
              }), regions.enumerated().allSatisfy({ i, r in !regions.prefix(i).contains(r) }) else { return nil }
        self.width = width; self.height = height; self.displayUUID = displayUUID; self.regions = regions
    }

    /// Shared selection gate for the runtime /info and event-channel profile.
    static func experimentalProfile(enabled: Bool, browserOnly: Bool, width: Int, height: Int, displayUUID: String) -> Self? {
        guard enabled, browserOnly else { return nil }
        // Conservative startup isolation: retain the original three primary-axis
        // regions. Five-area declarations failed before video in Build 9 device logs.
        // This is a diagnostic hypothesis, not a confirmed peer limit.
        return width >= height ? landscape(width: width, height: height, displayUUID: displayUUID) : portrait(width: width, height: height, displayUUID: displayUUID)
    }

    /// Full canvas plus two bounded horizontal profiles, no encoder size change.
    static func landscape(width: Int, height: Int, displayUUID: String) -> Self? {
        guard (960...16384).contains(width), (480...16384).contains(height), width >= height else { return nil }
        return Self(width: width, height: height, displayUUID: displayUUID, regions: [width, width * 2 / 3, width / 2].map {
            Region(x: 0, y: 0, width: $0, height: height)
        })
    }

    /// For a tall initial canvas, shorten the height rather than narrowing it further.
    /// Keep the same fixed raster and the same three-area experimental limit.
    static func portrait(width: Int, height: Int, displayUUID: String) -> Self? {
        guard (480...16384).contains(width), (960...16384).contains(height), height > width else { return nil }
        return Self(width: width, height: height, displayUUID: displayUUID, regions: [height, height * 2 / 3, height / 2].map {
            Region(x: 0, y: 0, width: width, height: $0)
        })
    }

    /// Select the closest predeclared aspect ratio by relative (logarithmic) error.
    /// Retain the previous recommendation unless the improvement exceeds 6%.
    /// This is a recommendation, not evidence of a phone-side layout change.
    func recommendedRegion(viewportWidth: Int, viewportHeight: Int, previous: Int? = nil) -> Int? {
        guard (1...32768).contains(viewportWidth), (1...32768).contains(viewportHeight) else { return nil }
        let aspect = Double(viewportWidth) / Double(viewportHeight)
        func error(_ index: Int) -> Double {
            let region = regions[index]
            return abs(log(aspect / (Double(region.width) / Double(region.height))))
        }
        guard let best = regions.indices.min(by: { error($0) < error($1) }) else { return nil }
        if let previous, regions.indices.contains(previous), error(previous) - error(best) < log(1.06) { return previous }
        return best
    }

    var displayFields: [String: Any] {
        let areas = regions.map { r -> [String: Any] in
            let bounds = ["widthPixels": r.width, "heightPixels": r.height, "originXPixels": r.x, "originYPixels": r.y]
            var safe: [String: Any] = bounds; safe["drawUIOutsideSafeArea"] = true
            var area: [String: Any] = bounds; area["safeArea"] = safe
            return area
        }
        return ["viewAreas": areas, "initialViewArea": 0, "viewAreaTransitionControl": true]
    }

    /// Validate the exact serialized /info display, including UUID and ordered geometry.
    /// This confirms our declaration only, never peer acceptance or presentation.
    func matchesDeclaration(_ body: Data) -> Bool {
        guard let info = (try? PropertyListSerialization.propertyList(from: body, format: nil)) as? [String: Any],
              let displays = info["displays"] as? [[String: Any]],
              displays.count == 1, let d = displays.first,
              d["uuid"] as? String == displayUUID,
              d["widthPixels"] as? Int == width, d["heightPixels"] as? Int == height,
              d["initialViewArea"] as? Int == 0,
              d["viewAreaTransitionControl"] as? Bool == true,
              let areas = d["viewAreas"] as? [[String: Any]], areas.count == regions.count else { return false }
        func matches(_ a: [String: Any], _ r: Region) -> Bool {
            a["widthPixels"] as? Int == r.width && a["heightPixels"] as? Int == r.height &&
            a["originXPixels"] as? Int == r.x && a["originYPixels"] as? Int == r.y
        }
        return zip(areas, regions).allSatisfy { pair in
            matches(pair.0, pair.1) && (pair.0["safeArea"] as? [String: Any]).map {
                matches($0, pair.1) && $0["drawUIOutsideSafeArea"] as? Bool == true
            } == true
        }
    }

    func command(index: Int) -> [String: Any]? {
        guard regions.indices.contains(index) else { return nil }
        let params: [String: Any] = ["uuid": displayUUID, "viewAreaIndex": index,
            "animationDurationMillis": 300, "adjacentViewAreas": regions.indices.filter { $0 != index }]
        return ["type": "updateViewArea", "params": params]
    }
}
