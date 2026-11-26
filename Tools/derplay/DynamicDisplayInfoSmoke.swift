import Foundation

// Minimal test double for UIKit/Darwin-dependent configuration. Exercise actual
// CarPlayInfo.build, HID descriptors and binary plist on the offline host.
struct ReceiverConfiguration {
    enum Codec { case h264, h265 }
    var width = 1920, height = 1080, maxFPS = 30, widthPhysicalMM = 200
    var audioEnabled = false, rightHandDrive = false
    var dockPosition: DerPlayDockPosition = .automatic
    var name = "DerPlay", deviceID = "00:11:22:33:44:55", oemIconLabel = "DerPlay"
    var oemIconPNG: Data? = nil
    var videoCodec: Codec = .h264
    var dynamicDisplayProfile: DynamicDisplayWire? = nil
}
@main struct DynamicDisplayInfoSmoke {
    static func main() throws {
        var config = ReceiverConfiguration()
        let baseline = CarPlayInfo.build(config)
        func display(_ info: [String: Any]) -> [String: Any] {
            (info["displays"] as! [[String: Any]])[0]
        }
        precondition((display(baseline)["viewAreas"] as! [[String: Any]]).count == 1)
        precondition(display(baseline)["viewAreaTransitionControl"] == nil)
        config.dynamicDisplayProfile = DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: config.width, height: config.height, displayUUID: CarPlayInfo.displayID)
        let info = CarPlayInfo.build(config)
        let encoded = try PropertyListSerialization.data(fromPropertyList: info, format: .binary, options: 0)
        let decoded = try PropertyListSerialization.propertyList(from: encoded, format: nil) as! [String: Any]
        let profile = config.dynamicDisplayProfile!
        precondition(profile.matchesDeclaration(encoded))
        func rejects(_ edit: (inout [String: Any]) -> Void) throws {
            var changed = decoded
            var displays = changed["displays"] as! [[String: Any]]
            edit(&displays[0]); changed["displays"] = displays
            let bytes = try PropertyListSerialization.data(fromPropertyList: changed, format: .binary, options: 0)
            precondition(!profile.matchesDeclaration(bytes))
        }
        try rejects { $0["uuid"] = "wrong" }
        try rejects { $0["initialViewArea"] = 1 }
        try rejects { $0["viewAreaTransitionControl"] = false }
        try rejects { d in
            var areas = d["viewAreas"] as! [[String: Any]]
            areas.swapAt(1, 2); d["viewAreas"] = areas
        }
        try rejects { d in
            var areas = d["viewAreas"] as! [[String: Any]]
            var safe = areas[1]["safeArea"] as! [String: Any]
            safe["originXPixels"] = 1; areas[1]["safeArea"] = safe; d["viewAreas"] = areas
        }
        precondition(!profile.matchesDeclaration(Data()))

        let d = display(decoded)
        precondition(d["initialViewArea"] as? Int == 0)
        precondition(d["viewAreaTransitionControl"] as? Bool == true)
        precondition(d["uuid"] as? String == CarPlayInfo.displayID)
        precondition(d["widthPixels"] as? Int == 1920 && d["heightPixels"] as? Int == 1080)
        let areas = d["viewAreas"] as! [[String: Any]]
        precondition(areas.compactMap { $0["widthPixels"] as? Int } == [1920, 1280, 960])
        precondition(areas.compactMap { $0["heightPixels"] as? Int } == [1080, 1080, 1080])
        precondition(NSArray(array: baseline["hidDevices"] as! [[String: Any]]).isEqual(to: decoded["hidDevices"] as! [[String: Any]]))
        config.width = 1104; config.height = 1212
        config.dynamicDisplayProfile = DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: config.width, height: config.height, displayUUID: CarPlayInfo.displayID)
        let tall = display(CarPlayInfo.build(config))
        precondition(tall["widthPixels"] as? Int == 1104 && tall["heightPixels"] as? Int == 1212)
        precondition((tall["viewAreas"] as! [[String: Any]]).compactMap { $0["heightPixels"] as? Int } == [1212, 808, 606])
        // Test actual serialized per-area key in both static and dynamic profiles.
        for dynamic in [false, true] {
            config.dynamicDisplayProfile = dynamic ? DynamicDisplayWire.experimentalProfile(enabled: true, browserOnly: true, width: config.width, height: config.height, displayUUID: CarPlayInfo.displayID) : nil
            for legacy in [false, true] {
                config.rightHandDrive = legacy
                for choice in DerPlayDockPosition.allCases {
                    config.dockPosition = choice
                    let wire = try PropertyListSerialization.data(fromPropertyList: CarPlayInfo.build(config), format: .binary, options: 0)
                    let info = try PropertyListSerialization.propertyList(from: wire, format: nil) as! [String: Any]
                    let areas = display(info)["viewAreas"] as! [[String: Any]]
                    precondition(areas.allSatisfy { ($0["viewAreaStatusBarEdge"] as? Int) == choice.edge })
                    precondition(info["rightHandDrive"] as? Bool == choice.driverSide(legacy: legacy))
                    precondition(areas.allSatisfy { $0["safeArea"] != nil })
                    if let profile = config.dynamicDisplayProfile { precondition(profile.matchesDeclaration(wire)) }
                }
            }
        }
        precondition(DerPlayDockPosition.automatic.edge == nil && DerPlayDockPosition.bottom.edge == 1 && DerPlayDockPosition.left.edge == 2 && DerPlayDockPosition.right.edge == 2)
        precondition(!DerPlayDockPosition.left.driverSide(legacy: true) && DerPlayDockPosition.right.driverSide(legacy: false))
        let suite = "derplay.dock.smoke.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(DerPlayDockPosition.saved(in: defaults) == .automatic)
        defaults.set("invalid", forKey: DerPlayDockPosition.defaultsKey)
        precondition(DerPlayDockPosition.saved(in: defaults) == .automatic)
        defaults.set("bottom", forKey: DerPlayDockPosition.defaultsKey)
        precondition(DerPlayDockPosition.saved(in: defaults) == .bottom)
        print("Dock serialization: 16 combinations + preference fallback passed")
        print("DynamicDisplayInfoSmoke: actual /info builder, default vs experimental, fixed raster and HID passed (configuration test double)")
    }
}
