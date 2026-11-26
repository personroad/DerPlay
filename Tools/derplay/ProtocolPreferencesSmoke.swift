import Foundation

@main struct ProtocolPreferencesSmoke {
    static func main() {
        let suite = "derplay.protocol-preferences.smoke.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DerPlayProtocolPreferences(defaults: defaults)
        let local = DerPlayProtocolPreferences.scope(output: 0, browserEnabled: false)
        let browser = DerPlayProtocolPreferences.scope(output: 0, browserEnabled: true)
        let carLife = DerPlayProtocolPreferences.scope(output: 1, browserEnabled: true)
        let airPlay = DerPlayProtocolPreferences.scope(output: 2, browserEnabled: true)
        precondition(Set((1...11).map { DerPlayProtocolPreferences.scope(output: $0, browserEnabled: true) } + [local,browser]).count == 13)
        precondition(carLife == DerPlayProtocolPreferences.scope(output: 1, browserEnabled: false))
        defaults.set(3, forKey: "displayResolutionIndex")
        defaults.set("16:9", forKey: "displayAspectRatio")
        defaults.set("left", forKey: "derplay.dockPosition")
        defaults.set(8080, forKey: "videoOutputPort")
        defaults.set("global-network", forKey: "wifiSSID")
        defaults.set(true, forKey: "backgroundKeepAlive")
        store.transition(from: browser, to: carLife)
        precondition(defaults.object(forKey: "displayResolutionIndex") == nil)
        precondition(defaults.object(forKey: "displayAspectRatio") == nil)
        precondition(defaults.object(forKey: "videoOutputPort") == nil)
        defaults.set(1, forKey: "displayResolutionIndex")
        defaults.set("bottom", forKey: "derplay.dockPosition")
        store.transition(from: carLife, to: local)
        precondition(defaults.object(forKey: "derplay.dockPosition") == nil)
        defaults.set("right", forKey: "derplay.dockPosition")
        store.transition(from: local, to: airPlay)
        defaults.set(9999, forKey: "videoOutputPort")
        store.transition(from: airPlay, to: browser)
        precondition(defaults.integer(forKey: "displayResolutionIndex") == 3)
        precondition(defaults.string(forKey: "displayAspectRatio") == "16:9")
        precondition(defaults.string(forKey: "derplay.dockPosition") == "left")
        precondition(defaults.integer(forKey: "videoOutputPort") == 8080)
        let reopened = DerPlayProtocolPreferences(defaults: UserDefaults(suiteName: suite)!)
        reopened.transition(from: browser, to: carLife)
        precondition(defaults.integer(forKey: "displayResolutionIndex") == 1)
        precondition(defaults.string(forKey: "derplay.dockPosition") == "bottom")
        reopened.transition(from: carLife, to: airPlay)
        precondition(defaults.integer(forKey: "videoOutputPort") == 9999)
        reopened.transition(from: airPlay, to: local)
        precondition(defaults.string(forKey: "derplay.dockPosition") == "right")
        reopened.transition(from: local, to: local)
        precondition(defaults.string(forKey: "derplay.dockPosition") == "right")
        precondition(defaults.string(forKey: "wifiSSID") == "global-network")
        precondition(defaults.bool(forKey: "backgroundKeepAlive"))
        // Simulate process interruption after legacy projection was partly changed.
        defaults.set(["old": local, "new": browser,
                      "outgoing": ["derplay.dockPosition": "right"],
                      "incoming": ["displayResolutionIndex": 3, "derplay.dockPosition": "left"],
                      "output": 0, "browser": true], forKey: DerPlayProtocolPreferences.pendingKey)
        defaults.set("bottom", forKey: "derplay.dockPosition")
        defaults.set(9999, forKey: "videoOutputPort")
        reopened.recoverPendingTransition()
        precondition(defaults.string(forKey: "derplay.dockPosition") == "left")
        precondition(defaults.integer(forKey: "displayResolutionIndex") == 3)
        precondition(defaults.object(forKey: "videoOutputPort") == nil)
        precondition(defaults.integer(forKey: "headUnitOutputV2") == 0)
        precondition(defaults.bool(forKey: "videoOutputEnabled"))
        precondition(defaults.object(forKey: DerPlayProtocolPreferences.pendingKey) == nil)
        reopened.recoverPendingTransition()
        reopened.transition(from: browser, to: local)
        precondition(defaults.string(forKey: "derplay.dockPosition") == "right")
        precondition(!defaults.bool(forKey: "videoOutputEnabled"))
        // Shared legacy controls now have independent model snapshots.
        for (first, second, address, auto) in [
            ("output-4", "output-6", "ninebotAddress", ""),
            ("output-5", "output-9", "zeehoAddress", "zeeho62AutomaticAddress"),
            ("output-10", "output-11", "cfmotoAddress", "")
        ] {
            reopened.transition(from: local, to: first)
            defaults.set("192.168.7.1", forKey: address)
            if !auto.isEmpty { defaults.set(false, forKey: auto) }
            reopened.transition(from: first, to: second)
            precondition(defaults.object(forKey: address) == nil)
            if !auto.isEmpty { precondition(defaults.object(forKey: auto) == nil) }
            defaults.set("192.168.8.1", forKey: address)
            if !auto.isEmpty { defaults.set(true, forKey: auto) }
            reopened.transition(from: second, to: first)
            precondition(defaults.string(forKey: address) == "192.168.7.1")
            if !auto.isEmpty { precondition(!defaults.bool(forKey: auto)) }
            reopened.transition(from: first, to: second)
            precondition(defaults.string(forKey: address) == "192.168.8.1")
            if !auto.isEmpty { precondition(defaults.bool(forKey: auto)) }
            reopened.transition(from: second, to: local)
        }
        // Old pending records must not clear newly scoped fields.
        defaults.set("192.168.9.1", forKey: "ninebotAddress")
        defaults.set(["old": local, "new": "output-4", "outgoing": [:], "incoming": [:],
                      "output": 4, "browser": true], forKey: DerPlayProtocolPreferences.pendingKey)
        reopened.recoverPendingTransition()
        precondition(defaults.string(forKey: "ninebotAddress") == "192.168.9.1")
        // Replay a new model transition after the active address has been partially overwritten.
        defaults.set(["old": "output-4", "new": "output-6",
                      "outgoing": ["ninebotAddress": "192.168.9.1"],
                      "incoming": ["ninebotAddress": "192.168.8.1"],
                      "output": 6, "browser": true, "instrumentIsolation": true], forKey: DerPlayProtocolPreferences.pendingKey)
        defaults.set("partial", forKey: "ninebotAddress")
        reopened.recoverPendingTransition()
        precondition(defaults.string(forKey: "ninebotAddress") == "192.168.8.1")
        reopened.transition(from: "output-6", to: "output-4")
        precondition(defaults.string(forKey: "ninebotAddress") == "192.168.9.1")
        print("Shared instrument address isolation and legacy recovery PASS")
        print("Interrupted transition replay and idempotence PASS")
        print("Protocol preferences smoke: 13 scopes, legacy migration, independent settings, reopen, no-op and global preservation PASS")
    }
}
