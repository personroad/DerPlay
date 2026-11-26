import Foundation

/// Display-profile policy. Geometry is a user-approved grouping key, not authentication.
/// Callers must supply current receiver-reported dimensions, never cached or output dimensions.
struct DeviceProfilePolicy {
    enum Evidence {
        case verifiedPeer(namespace: String, identifier: String)
        case browserPage(UUID)
        case networkAddress(String)
        case screenGeometry(Int, Int)
        case unavailable
    }
    struct ProfileKey: Codable, Hashable {
        let scope: String
        let namespace: String
        let identifier: String
    }
    struct DisplayPreference: Codable, Equatable {
        let resolutionIndex: Int
        let aspectRatio: String
        let iconWidthMM: Int?
        // Optional fields keep R16–R19 records readable. These are user preferences,
        // not negotiated receiver capabilities. Runtime must enforce protocol limits.
        let appearance: Int?
        let dockPosition: String?
        let soundOutput: Int?
        let rightHandDrive: Bool?
        let maxFPS: Int?
        let videoCodec: String?
        let sizeMode: Int?
        let carButton: Bool?
        init(resolutionIndex: Int, aspectRatio: String, iconWidthMM: Int? = nil,
             appearance: Int? = nil, dockPosition: String? = nil, soundOutput: Int? = nil,
             rightHandDrive: Bool? = nil, maxFPS: Int? = nil, videoCodec: String? = nil,
             sizeMode: Int? = nil, carButton: Bool? = nil) {
            self.resolutionIndex = resolutionIndex
            self.aspectRatio = aspectRatio
            self.iconWidthMM = iconWidthMM
            self.appearance = appearance
            self.dockPosition = dockPosition
            self.soundOutput = soundOutput
            self.rightHandDrive = rightHandDrive
            self.maxFPS = maxFPS
            self.videoCodec = videoCodec
            self.sizeMode = sizeMode
            self.carButton = carButton
        }
        /// Update only fields currently wired into the CarLife runtime.
        func replacingLayout(resolutionIndex: Int, iconWidthMM: Int, appearance: Int,
                             dockPosition: String, rightHandDrive: Bool,
                             soundOutput: Int? = nil, carButton: Bool? = nil) -> Self {
            Self(resolutionIndex: resolutionIndex, aspectRatio: aspectRatio,
                 iconWidthMM: iconWidthMM, appearance: appearance, dockPosition: dockPosition,
                 soundOutput: soundOutput ?? self.soundOutput, rightHandDrive: rightHandDrive, maxFPS: maxFPS,
                 videoCodec: videoCodec, sizeMode: sizeMode, carButton: carButton ?? self.carButton)
        }
        /// The preset uses the resolution tier's native aspect. Older auto placeholders stay automatic.
        func pictureIndex(allowedRatios: [String]) -> Int {
            guard sizeMode == 1 else { return 0 }
            if aspectRatio == "preset" { return 1 }
            return allowedRatios.firstIndex(of: aspectRatio).map { $0 + 2 } ?? 0
        }
        func replacingPicture(index: Int, allowedRatios: [String]) -> Self? {
            guard (0...allowedRatios.count + 1).contains(index) else { return nil }
            let ratio = index == 0 ? "auto" : index == 1 ? "preset" : allowedRatios[index - 2]
            return Self(resolutionIndex: resolutionIndex, aspectRatio: ratio, iconWidthMM: iconWidthMM,
                        appearance: appearance, dockPosition: dockPosition, soundOutput: soundOutput,
                        rightHandDrive: rightHandDrive, maxFPS: maxFPS, videoCodec: videoCodec,
                        sizeMode: index == 0 ? 0 : 1, carButton: carButton)
        }
        /// Restore supported preference values, not negotiated wire capabilities.
        func videoPreference(fallbackFPS: Int, fallbackCodec: String) -> (fps: Int, codec: String) {
            let fps = maxFPS.flatMap { [0, 30, 60].contains($0) ? $0 : nil } ?? fallbackFPS
            let codec = videoCodec.flatMap { ["auto", "h264", "h265"].contains($0) ? $0 : nil } ?? fallbackCodec
            return ([0, 30, 60].contains(fps) ? fps : 30,
                    ["auto", "h264", "h265"].contains(codec) ? codec : "h264")
        }
        func replacingVideo(fps: Int, codec: String) -> Self {
            Self(resolutionIndex: resolutionIndex, aspectRatio: aspectRatio, iconWidthMM: iconWidthMM,
                 appearance: appearance, dockPosition: dockPosition, soundOutput: soundOutput,
                 rightHandDrive: rightHandDrive, maxFPS: fps, videoCodec: codec,
                 sizeMode: sizeMode, carButton: carButton)
        }
        /// Use the same validation for stored snapshots and explicit writes.
        var validSnapshot: Bool {
            resolutionIndex >= 0 && validAdditionalPreferences &&
            DeviceProfilePolicy.valid(aspectRatio, limit: 32)
        }
        var validAdditionalPreferences: Bool {
            (appearance.map { (0...2).contains($0) } ?? true) &&
            (dockPosition.map { ["automatic", "left", "right", "bottom"].contains($0) } ?? true) &&
            (soundOutput.map { (0...2).contains($0) } ?? true) &&
            (maxFPS.map { [0, 30, 60].contains($0) } ?? true) &&
            (videoCodec.map { ["auto", "h264", "h265"].contains($0) } ?? true) &&
            (sizeMode.map { (0...1).contains($0) } ?? true)
        }
    }
    private struct Entry: Codable {
        let key: ProfileKey
        let preference: DisplayPreference
    }
    /// A malformed record must not prevent other screens from restoring their settings.
    private struct DecodableEntry: Decodable {
        let entry: Entry?
        init(from decoder: Decoder) throws {
            entry = try? Entry(from: decoder)
        }
    }
    private static func isValidStoredKey(_ key: ProfileKey) -> Bool {
        if key.namespace == "screen-geometry-v1" {
            let parts = key.identifier.split(separator: "x", omittingEmptySubsequences: false)
            guard parts.count == 2, let width = Int(parts[0]), let height = Int(parts[1]) else { return false }
            return Self.key(scope: key.scope, evidence: .screenGeometry(width, height)) == key
        }
        return Self.key(scope: key.scope, evidence: .verifiedPeer(namespace: key.namespace, identifier: key.identifier)) == key
    }
    private let defaults: UserDefaults
    private let storageKey = "derplay.verifiedDeviceProfiles.v1"
    private let maximum = 32
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    static func key(scope: String, evidence: Evidence) -> ProfileKey? {
        // Browser layout preferences are protocol-wide, never screen-keyed.
        guard (1...11).contains(where: { scope == "output-\($0)" }) else { return nil }
        switch evidence {
        case let .screenGeometry(width, height):
            guard (320...16384).contains(width), (320...16384).contains(height) else { return nil }
            return ProfileKey(scope: scope, namespace: "screen-geometry-v1", identifier: "\(width)x\(height)")
        case let .verifiedPeer(namespace, identifier):
            guard namespace != "screen-geometry-v1", valid(namespace, limit: 64), valid(identifier, limit: 256) else { return nil }
            return ProfileKey(scope: scope, namespace: namespace, identifier: identifier)
        default: return nil
        }
    }
    private static func valid(_ value: String, limit: Int) -> Bool {
        !value.isEmpty && value.utf8.count <= limit &&
        value.utf8.allSatisfy { (33...126).contains($0) }
    }
    private func entries() -> [Entry] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DecodableEntry].self, from: data) else { return [] }
        let entries = decoded.compactMap(\.entry)
        // Ignore obsolete browser entries from R18; they must not evict vehicle profiles.
        var seen = Set<ProfileKey>()
        return Array(entries.filter { $0.key.scope != "browser" }
            .filter { Self.isValidStoredKey($0.key) && $0.preference.validSnapshot && seen.insert($0.key).inserted }
            .prefix(maximum))
    }
    func lookup(scope: String, evidence: Evidence) -> DisplayPreference? {
        guard let key = Self.key(scope: scope, evidence: evidence) else { return nil }
        return entries().first { $0.key == key }?.preference
    }
    /// Resolve a saved tier against the current supported list; never trust persisted indices.
    func resolutionIndex(scope: String, evidence: Evidence, fallback: Int, count: Int) -> Int {
        guard let saved = lookup(scope: scope, evidence: evidence),
              (0..<count).contains(saved.resolutionIndex) else { return fallback }
        return saved.resolutionIndex
    }
    func iconWidthMM(scope: String, evidence: Evidence, fallback: Int, allowed: [Int]) -> Int {
        guard let width = lookup(scope: scope, evidence: evidence)?.iconWidthMM,
              allowed.contains(width) else { return fallback }
        return width
    }
    /// Explicit preference snapshot only, never a screen capability report.
    @discardableResult
    func save(_ preference: DisplayPreference, scope: String, evidence: Evidence) -> Bool {
        guard let key = Self.key(scope: scope, evidence: evidence),
              preference.validSnapshot else { return false }
        let updated = [Entry(key: key, preference: preference)] + entries().filter { $0.key != key }
        guard let data = try? JSONEncoder().encode(Array(updated.prefix(maximum))) else { return false }
        defaults.set(data, forKey: storageKey)
        return true
    }
}
