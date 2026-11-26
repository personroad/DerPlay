import Foundation

@main struct DeviceProfilePolicySmoke {
    static func main() {
        let suite = "derplay.device-profile.smoke.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DeviceProfilePolicy(defaults: defaults)
        let a = DeviceProfilePolicy.Evidence.verifiedPeer(namespace: "test", identifier: "A")
        let b = DeviceProfilePolicy.Evidence.verifiedPeer(namespace: "test", identifier: "B")
        let first = DeviceProfilePolicy.DisplayPreference(resolutionIndex: 1, aspectRatio: "16:9")
        let second = DeviceProfilePolicy.DisplayPreference(resolutionIndex: 2, aspectRatio: "20:9")
        precondition(store.save(first, scope: "output-2", evidence: a))
        precondition(store.save(second, scope: "output-2", evidence: b))
        precondition(store.save(second, scope: "output-1", evidence: a))
        let reopened = DeviceProfilePolicy(defaults: UserDefaults(suiteName: suite)!)
        precondition(reopened.lookup(scope: "output-2", evidence: a) == first)
        precondition(reopened.lookup(scope: "output-2", evidence: b) == second)
        precondition(reopened.lookup(scope: "output-1", evidence: a) == second)
        precondition(reopened.lookup(scope: "output-3", evidence: a) == nil)
        for evidence in [DeviceProfilePolicy.Evidence.browserPage(UUID()), .networkAddress("192.168.1.1"), .screenGeometry(0, 720), .screenGeometry(1280, 999999), .unavailable, .verifiedPeer(namespace: "", identifier: "A")] {
            precondition(!store.save(first, scope: "output-2", evidence: evidence))
            precondition(store.lookup(scope: "output-2", evidence: evidence) == nil)
        }
        precondition(!store.save(first, scope: "local", evidence: a))
        precondition(store.lookup(scope: "output-2", evidence: .verifiedPeer(namespace: "other", identifier: "A")) == nil)
        let hd = DeviceProfilePolicy.Evidence.screenGeometry(1280, 720)
        let fhd = DeviceProfilePolicy.Evidence.screenGeometry(1920, 1080)
        precondition(DeviceProfilePolicy.key(scope: "browser", evidence: hd) == nil)
        precondition(!store.save(first, scope: "browser", evidence: hd))
        precondition(!store.save(first, scope: "browser", evidence: a))
        precondition(store.lookup(scope: "browser", evidence: hd) == nil)
        precondition(store.save(first, scope: "output-2", evidence: hd))
        precondition(store.save(second, scope: "output-2", evidence: fhd))
        precondition(store.save(second, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-2", evidence: hd) == first)
        precondition(reopened.lookup(scope: "output-2", evidence: fhd) == second)
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == second)
        precondition(reopened.lookup(scope: "output-2", evidence: .screenGeometry(720, 1280)) == nil)
        precondition(reopened.lookup(scope: "output-2", evidence: .verifiedPeer(namespace: "screen-geometry-v1", identifier: "1280x720")) == nil)
        precondition(store.resolutionIndex(scope: "output-1", evidence: hd, fallback: 0, count: 5) == 2)
        precondition(store.resolutionIndex(scope: "output-1", evidence: fhd, fallback: 1, count: 5) == 1)
        precondition(store.resolutionIndex(scope: "output-1", evidence: hd, fallback: 0, count: 2) == 0)
        // Legacy records without an icon field remain readable; unsupported values fall back.
        precondition(store.iconWidthMM(scope: "output-1", evidence: hd, fallback: 200, allowed: [125, 200, 250, 300]) == 200)
        let large = DeviceProfilePolicy.DisplayPreference(resolutionIndex: 2, aspectRatio: "auto", iconWidthMM: 125)
        let small = DeviceProfilePolicy.DisplayPreference(resolutionIndex: 1, aspectRatio: "auto", iconWidthMM: 300)
        precondition(store.save(large, scope: "output-1", evidence: hd))
        precondition(store.save(small, scope: "output-1", evidence: fhd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == large)
        precondition(reopened.iconWidthMM(scope: "output-1", evidence: fhd, fallback: 200, allowed: [125, 200, 250, 300]) == 300)
        precondition(reopened.iconWidthMM(scope: "output-2", evidence: hd, fallback: 200, allowed: [125, 200, 250, 300]) == 200)
        precondition(reopened.iconWidthMM(scope: "output-1", evidence: fhd, fallback: 200, allowed: [125, 200]) == 200)
        precondition(reopened.iconWidthMM(scope: "output-1", evidence: .screenGeometry(2560, 1440), fallback: 200, allowed: [125, 200, 250, 300]) == 200)
        // Decode an actual old-schema JSON record without iconWidthMM.
        let legacy = """
        [{"key":{"scope":"browser","namespace":"screen-geometry-v1","identifier":"1280x720"},"preference":{"resolutionIndex":4,"aspectRatio":"auto","iconWidthMM":300}},{"key":{"scope":"output-1","namespace":"screen-geometry-v1","identifier":"1280x720"},"preference":{"resolutionIndex":1,"aspectRatio":"auto"}}]
        """
        let legacySuite = suite + ".legacy"
        let legacyDefaults = UserDefaults(suiteName: legacySuite)!
        defer { legacyDefaults.removePersistentDomain(forName: legacySuite) }
        legacyDefaults.set(Data(legacy.utf8), forKey: "derplay.verifiedDeviceProfiles.v1")
        let legacyStore = DeviceProfilePolicy(defaults: legacyDefaults)
        precondition(legacyStore.lookup(scope: "browser", evidence: hd) == nil)
        precondition(legacyStore.resolutionIndex(scope: "browser", evidence: hd, fallback: 2, count: 5) == 2)
        precondition(legacyStore.lookup(scope: "output-1", evidence: hd)?.resolutionIndex == 1)
        precondition(legacyStore.iconWidthMM(scope: "output-1", evidence: hd, fallback: 200, allowed: [125, 200, 250, 300]) == 200)
        // R20: all eleven user-approved fields round-trip independently of browser defaults.
        let full = DeviceProfilePolicy.DisplayPreference(resolutionIndex: 2, aspectRatio: "20:9",
            iconWidthMM: 125, appearance: 2, dockPosition: "right", soundOutput: 1,
            rightHandDrive: true, maxFPS: 60, videoCodec: "h265", sizeMode: 1, carButton: false)
        precondition(store.save(full, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == full)
        precondition(reopened.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(reopened.lookup(scope: "output-2", evidence: hd) == first)
        precondition(!store.save(full, scope: "browser", evidence: hd))
        precondition(legacyStore.lookup(scope: "output-1", evidence: hd)?.dockPosition == nil)
        precondition(legacyStore.lookup(scope: "output-1", evidence: hd)?.maxFPS == nil)
        let invalid = DeviceProfilePolicy.DisplayPreference(resolutionIndex: 2, aspectRatio: "auto", maxFPS: 120)
        precondition(!store.save(invalid, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == full)
        // R21: editing a wired layout must retain every not-yet-wired field.
        let edited = full.replacingLayout(resolutionIndex: 1, iconWidthMM: 200,
            appearance: 1, dockPosition: "bottom", rightHandDrive: false)
        precondition(edited.resolutionIndex == 1 && edited.iconWidthMM == 200)
        precondition(edited.appearance == 1 && edited.dockPosition == "bottom" && edited.rightHandDrive == false)
        precondition(edited.aspectRatio == full.aspectRatio && edited.soundOutput == full.soundOutput)
        precondition(edited.maxFPS == full.maxFPS && edited.videoCodec == full.videoCodec)
        precondition(edited.sizeMode == full.sizeMode && edited.carButton == full.carButton)
        precondition(store.save(edited, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == edited)
        precondition(reopened.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(reopened.lookup(scope: "output-1", evidence: .screenGeometry(2560, 1440)) == nil)
        precondition(reopened.lookup(scope: "browser", evidence: hd) == nil)
        let oldLayout = legacyStore.lookup(scope: "output-1", evidence: hd)!
        let migrated = oldLayout.replacingLayout(resolutionIndex: 1, iconWidthMM: 200,
            appearance: 0, dockPosition: "automatic", rightHandDrive: false)
        precondition(legacyStore.save(migrated, scope: "output-1", evidence: hd))
        precondition(legacyStore.lookup(scope: "output-1", evidence: hd) == migrated)
        precondition(migrated.soundOutput == nil && migrated.maxFPS == nil)
        // R22: explicit vehicle-button false and sound value zero must not be lost.
        let audioVehicle = edited.replacingLayout(resolutionIndex: 1, iconWidthMM: 200,
            appearance: 1, dockPosition: "bottom", rightHandDrive: false,
            soundOutput: 0, carButton: true)
        precondition(audioVehicle.soundOutput == 0 && audioVehicle.carButton == true)
        let hidden = audioVehicle.replacingLayout(resolutionIndex: 1, iconWidthMM: 200,
            appearance: 1, dockPosition: "bottom", rightHandDrive: false,
            soundOutput: 1, carButton: false)
        precondition(hidden.soundOutput == 1 && hidden.carButton == false)
        precondition(hidden.aspectRatio == edited.aspectRatio && hidden.maxFPS == edited.maxFPS)
        precondition(hidden.videoCodec == edited.videoCodec && hidden.sizeMode == edited.sizeMode)
        precondition(store.save(hidden, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == hidden)
        precondition(reopened.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(legacyStore.lookup(scope: "output-1", evidence: hd)?.carButton == nil)
        // R23: ratio edits retain all nine unrelated fields and never modify another screen.
        let allowedRatios = ["16:9", "4:3", "4:1", "9:16"]
        precondition(hidden.pictureIndex(allowedRatios: allowedRatios) == 0) // unknown saved ratio
        let fixedPicture = hidden.replacingPicture(index: 3, allowedRatios: allowedRatios)!
        precondition(fixedPicture.aspectRatio == "4:3" && fixedPicture.sizeMode == 1)
        precondition(fixedPicture.pictureIndex(allowedRatios: allowedRatios) == 3)
        precondition(fixedPicture.resolutionIndex == hidden.resolutionIndex && fixedPicture.iconWidthMM == hidden.iconWidthMM)
        precondition(fixedPicture.appearance == hidden.appearance && fixedPicture.dockPosition == hidden.dockPosition)
        precondition(fixedPicture.rightHandDrive == hidden.rightHandDrive && fixedPicture.soundOutput == hidden.soundOutput)
        precondition(fixedPicture.maxFPS == hidden.maxFPS && fixedPicture.videoCodec == hidden.videoCodec && fixedPicture.carButton == hidden.carButton)
        precondition(store.save(fixedPicture, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == fixedPicture)
        precondition(reopened.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(!store.save(fixedPicture, scope: "browser", evidence: hd))
        precondition(fixedPicture.replacingPicture(index: -1, allowedRatios: allowedRatios) == nil)
        precondition(fixedPicture.replacingPicture(index: 6, allowedRatios: allowedRatios) == nil)
        let preset = fixedPicture.replacingPicture(index: 1, allowedRatios: allowedRatios)!
        precondition(preset.aspectRatio == "preset" && preset.sizeMode == 1 && preset.pictureIndex(allowedRatios: allowedRatios) == 1)
        let automatic = fixedPicture.replacingPicture(index: 0, allowedRatios: allowedRatios)!
        precondition(automatic.aspectRatio == "auto" && automatic.sizeMode == 0 && automatic.pictureIndex(allowedRatios: allowedRatios) == 0)
        precondition(migrated.pictureIndex(allowedRatios: allowedRatios) == 0)
        let fixedRaster = DerPlayCarLifeDisplay.fixedProfileSize(ratioWidth: 4, ratioHeight: 3, area: 1280*720)!
        precondition(fixedRaster.width % 2 == 0 && fixedRaster.height % 2 == 0 && fixedRaster.width*fixedRaster.height <= 1280*720)
        precondition(abs(Double(fixedRaster.width) / Double(fixedRaster.height) - 4.0/3.0) < 0.01)
        precondition(DerPlayCarLifeDisplay.fixedProfileSize(ratioWidth: 4, ratioHeight: 1, area: 800*480) == nil)
        precondition(DerPlayCarLifeDisplay.fixedProfileSize(ratioWidth: 0, ratioHeight: 1, area: 800*480) == nil)
        precondition(DerPlayCarLifeDisplay.fixedProfileSize(ratioWidth: 1, ratioHeight: 4, area: 1920*1080) == nil)
        var fixedNegotiation = DerPlayCarLifeDisplay.Negotiation(area: 1280*720)
        precondition(fixedNegotiation.commit(width: fixedRaster.width, height: fixedRaster.height))
        precondition(fixedNegotiation.selection(width: 1920, height: 1080)?.width == fixedRaster.width)
        // R24: video preferences round-trip without changing unrelated fields.
        let video = fixedPicture.replacingVideo(fps: 60, codec: "h265")
        precondition(video.videoPreference(fallbackFPS: 30, fallbackCodec: "h264").fps == 60)
        precondition(video.videoPreference(fallbackFPS: 30, fallbackCodec: "h264").codec == "h265")
        precondition(video.replacingVideo(fps: fixedPicture.maxFPS!, codec: fixedPicture.videoCodec!) == fixedPicture)
        precondition(store.save(video, scope: "output-1", evidence: hd))
        precondition(reopened.lookup(scope: "output-1", evidence: hd) == video)
        precondition(reopened.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(migrated.videoPreference(fallbackFPS: 30, fallbackCodec: "h264").fps == 30)
        precondition(migrated.videoPreference(fallbackFPS: 30, fallbackCodec: "h264").codec == "h264")
        let invalidVideo = video.replacingVideo(fps: 90, codec: "invalid")
        precondition(!store.save(invalidVideo, scope: "output-1", evidence: hd))
        precondition(invalidVideo.videoPreference(fallbackFPS: 0, fallbackCodec: "auto").fps == 0)
        precondition(invalidVideo.videoPreference(fallbackFPS: 0, fallbackCodec: "auto").codec == "auto")
        // R25: a malformed row or obsolete/duplicate keys cannot hide other screens.
        let mixedSuite = suite + ".mixed"
        let mixedDefaults = UserDefaults(suiteName: mixedSuite)!
        defer { mixedDefaults.removePersistentDomain(forName: mixedSuite) }
        let mixed = DeviceProfilePolicy(defaults: mixedDefaults)
        let storage = "derplay.verifiedDeviceProfiles.v1"
        precondition(mixed.save(video, scope: "output-1", evidence: hd))
        precondition(mixed.save(small, scope: "output-1", evidence: fhd))
        let rows = try! JSONSerialization.jsonObject(with: mixedDefaults.data(forKey: storage)!) as! [[String: Any]]
        let junk: [String: Any] = ["key": ["scope": "output-1", "namespace": "screen-geometry-v1", "identifier": "2560x1440"], "preference": ["resolutionIndex": "broken"]]
        let stale: [String: Any] = ["key": ["scope": "output-99", "namespace": "screen-geometry-v1", "identifier": "1280x720"], "preference": ["resolutionIndex": 0, "aspectRatio": "auto"]]
        let damaged: [Any] = [junk, NSNull()] + Array(repeating: stale, count: 35) + Array(repeating: rows[0], count: 35) + [rows[1]]
        mixedDefaults.set(try! JSONSerialization.data(withJSONObject: damaged), forKey: storage)
        precondition(mixed.lookup(scope: "output-1", evidence: hd) == video)
        precondition(mixed.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(mixed.lookup(scope: "output-1", evidence: .screenGeometry(2560, 1440)) == nil)
        // R26: syntactically valid JSON with invalid values must not shadow an older valid row.
        var invalidRow = rows[1]
        var invalidPreference = invalidRow["preference"] as! [String: Any]
        invalidPreference["maxFPS"] = 90
        invalidRow["preference"] = invalidPreference
        var negativeTier = rows[0]
        var negativePreference = negativeTier["preference"] as! [String: Any]
        negativePreference["resolutionIndex"] = -1
        negativeTier["preference"] = negativePreference
        var badRatio = rows[0]
        var badRatioPreference = badRatio["preference"] as! [String: Any]
        badRatioPreference["aspectRatio"] = ""
        badRatio["preference"] = badRatioPreference
        let invalidRows = [invalidRow, negativeTier, badRatio] + rows
        mixedDefaults.set(try! JSONSerialization.data(withJSONObject: invalidRows), forKey: storage)
        precondition(mixed.lookup(scope: "output-1", evidence: hd) == video)
        precondition(mixed.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(mixed.save(video, scope: "output-1", evidence: hd))
        precondition(mixed.lookup(scope: "output-1", evidence: fhd) == small)
        // Protocol transitions and independent browser Dock remain separate from all eleven screen fields.
        let protocols = DerPlayProtocolPreferences(defaults: mixedDefaults)
        mixedDefaults.set("left", forKey: "derplay.dockPosition")
        mixedDefaults.set(4, forKey: "displayResolutionIndex")
        protocols.transition(from: "output-1", to: "browser")
        mixedDefaults.set("bottom", forKey: "derplay.dockPosition")
        mixedDefaults.set(8080, forKey: "videoOutputPort")
        protocols.transition(from: "browser", to: "output-1")
        precondition(mixedDefaults.string(forKey: "derplay.dockPosition") == "left")
        precondition(mixedDefaults.integer(forKey: "displayResolutionIndex") == 4)
        precondition(mixed.save(video, scope: "output-1", evidence: hd))
        protocols.transition(from: "output-1", to: "browser")
        precondition(mixedDefaults.string(forKey: "derplay.dockPosition") == "bottom")
        precondition(mixedDefaults.integer(forKey: "videoOutputPort") == 8080)
        precondition(DeviceProfilePolicy(defaults: UserDefaults(suiteName: mixedSuite)!).lookup(scope: "output-1", evidence: hd) == video)
        precondition(mixed.lookup(scope: "output-1", evidence: fhd) == small)
        precondition(mixed.lookup(scope: "browser", evidence: hd) == nil)
        // Same raw report chooses the stored tier before the first raster is committed.
        let raw = DeviceProfilePolicy.Evidence.screenGeometry(1080, 2210)
        precondition(store.save(first, scope: "output-1", evidence: raw))
        let areas = [800 * 480, 1280 * 720, 1920 * 1080]
        let tier = store.resolutionIndex(scope: "output-1", evidence: raw, fallback: 2, count: areas.count)
        var negotiation = DerPlayCarLifeDisplay.Negotiation(area: areas[tier])
        let raster = negotiation.selection(width: 1080, height: 2210)!
        precondition(tier == 1 && raster.width == 1370 && raster.height == 670)
        precondition(negotiation.commit(width: raster.width, height: raster.height))
        precondition(negotiation.selection(width: 1920, height: 1080)?.width == raster.width)
        for i in 0..<32 {
            precondition(store.save(first, scope: "output-2", evidence: .verifiedPeer(namespace: "test", identifier: "new-\(i)")))
        }
        precondition(store.lookup(scope: "output-2", evidence: a) == nil)
        precondition(store.lookup(scope: "output-2", evidence: .verifiedPeer(namespace: "test", identifier: "new-31")) == first)
        defaults.set(Data([0xff]), forKey: "derplay.verifiedDeviceProfiles.v1")
        precondition(store.lookup(scope: "output-2", evidence: b) == nil)
        print("DeviceProfilePolicy smoke PASS")
    }
}
