import Foundation
@main struct WiFiPresetSmoke {
    static func main() {
        let suite = "derplay.wifi.smoke." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(WiFiPresetStore.legacyChannel(defaults) == 36)
        for raw in [Int.min, -1, 0, 197, 256, Int.max] {
            defaults.set(raw, forKey: "wifiChannel")
            precondition(WiFiPresetStore.legacyChannel(defaults) == 36)
        }
        for raw in [1, 36, 149, 196] {
            defaults.set(raw, forKey: "wifiChannel")
            precondition(WiFiPresetStore.legacyChannel(defaults) == UInt8(raw))
        }
        print("Wi-Fi legacy channel smoke PASS")
    }
}
