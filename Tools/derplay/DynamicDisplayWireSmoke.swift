import Foundation
@main struct DynamicDisplayWireSmoke {
    static func main() throws {
        let uuid = "b7e6c5a0-1111-4000-8000-000000000001"
        let p = DynamicDisplayWire.landscape(width: 1920, height: 1080, displayUUID: uuid)!
        precondition(p.regions.map(\.width) == [1920, 1280, 960])
        precondition(p.command(index: -1) == nil && p.command(index: 3) == nil)
        precondition(DynamicDisplayWire.landscape(width: 1920, height: 1080, displayUUID: "bad") == nil)
        precondition(DynamicDisplayWire.landscape(width: 100, height: 100, displayUUID: uuid) == nil)
        precondition(DynamicDisplayWire.experimentalProfile(enabled: false, browserOnly: true, width: 1920, height: 1080, displayUUID: uuid) == nil)
        precondition(DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: false, width: 1920, height: 1080, displayUUID: uuid) == nil)
        precondition(DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: 800, height: 480, displayUUID: uuid) == nil)
        let selected = DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: 1920, height: 1080, displayUUID: uuid)!
        precondition(Array(selected.regions.prefix(3)) == p.regions)
        precondition(selected.regions.count == 3)
        precondition(selected.recommendedRegion(viewportWidth: 3840, viewportHeight: 1080) == 0)
        let logged = DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: 1644, height: 1212, displayUUID: uuid)!
        precondition(logged.recommendedRegion(viewportWidth: 957, viewportHeight: 1212) == 1)
        precondition(logged.recommendedRegion(viewportWidth: 2111, viewportHeight: 1212) == 0)
        precondition(p.recommendedRegion(viewportWidth: 1920, viewportHeight: 1080) == 0)
        precondition(p.recommendedRegion(viewportWidth: 1280, viewportHeight: 1080) == 1)
        precondition(p.recommendedRegion(viewportWidth: 960, viewportHeight: 1080) == 2)
        precondition(p.recommendedRegion(viewportWidth: 0, viewportHeight: 1080) == nil)
        precondition(p.recommendedRegion(viewportWidth: 1080, viewportHeight: 1920) == 2)
        precondition(p.recommendedRegion(viewportWidth: 1560, viewportHeight: 1080, previous: 1) == 1)
        precondition(p.recommendedRegion(viewportWidth: 1920, viewportHeight: 1080, previous: 1) == 0)
        precondition(p.recommendedRegion(viewportWidth: 1280, viewportHeight: 1080, previous: 99) == 1)
        let tall = DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: 1104, height: 1212, displayUUID: uuid)!
        precondition(tall.regions.map(\.height) == [1212, 808, 606])
        precondition(tall.regions.map(\.width) == [1104, 1104, 1104])
        precondition(tall.recommendedRegion(viewportWidth: 552, viewportHeight: 1212) == 0)
        precondition(tall.recommendedRegion(viewportWidth: 1104, viewportHeight: 1212) == 0)
        precondition(tall.recommendedRegion(viewportWidth: 1104, viewportHeight: 606) == 2)
        precondition(DynamicDisplayWire.experimentalProfile(enabled: false, browserOnly: true, width: 1104, height: 1212, displayUUID: uuid) == nil)
        let actual = DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: 1282, height: 1212, displayUUID: uuid)!
        precondition(actual.regions.map(\.width) == [1282, 854, 641])
        precondition(actual.regions.allSatisfy { $0.height == 1212 })
        precondition(actual.recommendedRegion(viewportWidth: 1282, viewportHeight: 1212) == 0)
        precondition(actual.command(index: 3) == nil)
        let fields = p.displayFields
        precondition(fields["viewAreaTransitionControl"] as? Bool == true)
        let areas = fields["viewAreas"] as! [[String: Any]]
        precondition(areas.count == 3 && areas[1]["widthPixels"] as? Int == 1280)
        precondition((areas[2]["safeArea"] as? [String: Any])?["widthPixels"] as? Int == 960)
        for i in 0..<3 {
            let data = try PropertyListSerialization.data(fromPropertyList: p.command(index: i)!, format: .binary, options: 0)
            let decoded = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
            let params = decoded["params"] as! [String: Any]
            precondition(decoded["type"] as? String == "updateViewArea")
            precondition(params["uuid"] as? String == uuid && params["viewAreaIndex"] as? Int == i)
            precondition(params["animationDurationMillis"] as? Int == 300)
            precondition(params["adjacentViewAreas"] as? [Int] == (0..<3).filter { $0 != i })
        }
        let full = p.regions[0]
        precondition(DynamicDisplayWire(width: 1920, height: 1080, displayUUID: uuid, regions: [full, full]) == nil)
        precondition(DynamicDisplayWire(width: 1920, height: 1080, displayUUID: uuid, regions: [full, .init(x: Int.max, y: 0, width: 1, height: 1)]) == nil)
        print("DynamicDisplayWireSmoke: passed (offline binary plist, no live session)")
    }
}
