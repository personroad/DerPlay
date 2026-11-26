import Foundation

/// Keeps the active legacy keys as a compatibility projection for the existing receiver.
/// Only explicit mode switches write snapshots; no device discovery or credentials here.
struct DerPlayProtocolPreferences {
    static let keys = ["displayResolutionIndex", "displayAspectRatio", "displayMaxFPS",
        "videoCodec", "displaySizeMode", "widthPhysicalMM", "carPlayAppearance",
        "derplay.dockPosition", "rightHandDrive", "portraitDisplay", "soundOutput",
        "videoOutputPort", "secureVideoOutputPort", "carButton"]
    // Shared legacy instrument fields belong only to their active model.
    static func instrumentKeys(_ scope: String) -> [String] {
        switch scope {
        case "output-4", "output-6": return ["ninebotAddress"]
        case "output-5", "output-9": return ["zeehoAddress", "zeeho62AutomaticAddress"]
        case "output-10", "output-11": return ["cfmotoAddress"]
        default: return []
        }
    }
    let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    static func scope(output: Int, browserEnabled: Bool) -> String {
        output == 0 ? (browserEnabled ? "browser" : "local") : "output-\(output)"
    }
    private func key(_ scope: String) -> String { "derplay.protocolPreferences.v1.\(scope)" }
    static let pendingKey = "derplay.protocolPreferences.pending.v1"

    /// Replay an interrupted transition before reading any legacy controls.
    /// UserDefaults persistence is asynchronous; this is replay protection, not a disk transaction.
    func recoverPendingTransition() {
        guard let pending = defaults.dictionary(forKey: Self.pendingKey),
              let old = pending["old"] as? String,
              let new = pending["new"] as? String,
              old != new,
              let outgoing = pending["outgoing"] as? [String: Any],
              let incoming = pending["incoming"] as? [String: Any],
              let output = pending["output"] as? Int,
              let browser = pending["browser"] as? Bool,
              (0...11).contains(output), Self.scope(output: output, browserEnabled: browser) == new else { return }
        defaults.set(outgoing, forKey: key(old))
        for name in Self.keys + (pending["instrumentIsolation"] as? Bool == true ? Self.instrumentKeys(new) : []) {
            if let value = incoming[name] { defaults.set(value, forKey: name) }
            else { defaults.removeObject(forKey: name) }
        }
        defaults.set(output, forKey: "headUnitOutputV2")
        defaults.set(browser, forKey: "videoOutputEnabled")
        defaults.removeObject(forKey: Self.pendingKey)
    }
    func transition(from old: String, to new: String) {
        guard old != new else { return }
        var snapshot: [String: Any] = [:]
        for name in Self.keys + Self.instrumentKeys(old) { snapshot[name] = defaults.object(forKey: name) }
        let incoming = defaults.dictionary(forKey: key(new)) ?? [:]
        let output: Int
        let browser: Bool
        switch new {
        case "local": output = 0; browser = false
        case "browser": output = 0; browser = true
        default:
            guard new.hasPrefix("output-"), let raw = Int(new.dropFirst(7)), (1...11).contains(raw) else { return }
            output = raw
            browser = defaults.object(forKey: "videoOutputEnabled") as? Bool ?? true
        }
        defaults.set(["old": old, "new": new, "outgoing": snapshot, "incoming": incoming,
                      "output": output, "browser": browser, "instrumentIsolation": true], forKey: Self.pendingKey)
        recoverPendingTransition()
    }
}
