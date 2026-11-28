import Foundation
struct BrowserDisplay: Equatable {
    let width: Int, height: Int
    let screenWidth: Int?, screenHeight: Int?
    let devicePixelRatio: Double
    let refreshHz: Int
    let supportsH265: Bool
    let fullscreen: Bool
    let peer: String
}
@main struct CarScreenStoreSmoke {
    static func main() {
        let d = UserDefaults.standard
        let keys = ["carScreens", "carScreenDefault", "derplay.carLife.lastNegotiation"]
        let saved = keys.map { d.object(forKey: $0) }
        defer { for (key, value) in zip(keys, saved) { d.set(value, forKey: key) } }
        keys.forEach { d.removeObject(forKey: $0) }
        let b = CarScreenStore.record(BrowserDisplay(width: 1282, height: 1212, screenWidth: 1282, screenHeight: 1212, devicePixelRatio: 1, refreshHz: 57, supportsH265: true, fullscreen: false, peer: "test"))
        CarScreenStore.setDefault(b.key)
        CarScreenStore.setIconWidth(120, for: b.key)
        let current = CarScreenStore.recordCurrent(BrowserDisplay(width: 1282, height: 1212, screenWidth: 1282, screenHeight: 1212, devicePixelRatio: 1, refreshHz: 30, supportsH265: false, fullscreen: false, peer: "different-viewer"))
        assert(current.iconWidthMM == nil && current.refreshHz == 30 && !current.supportsH265)
        assert(current.nativeWidth == 1282 && current.nativeHeight == 1212)
        assert(CarScreenStore.preferred()?.iconWidthMM == 120)
        let before = CarScreenStore.screens()
        let c = CarScreen(width: 526, height: 1080, devicePixelRatio: 1, refreshHz: 30, supportsH265: false, lastUsed: Date(), profileKey: nil, iconWidthMM: nil)
        CarScreenStore.recordCarLifeNegotiation(c)
        assert(CarScreenStore.lastCarLifeNegotiation() == c)
        assert(CarScreenStore.screens() == before && CarScreenStore.preferred()?.iconWidthMM == 120)
        CarScreenStore.clearCarLifeNegotiation()
        assert(CarScreenStore.lastCarLifeNegotiation() == nil && CarScreenStore.screens() == before && CarScreenStore.defaultKeyValue == b.key)
        let legacy = "{\"width\":900,\"height\":1900,\"devicePixelRatio\":1,\"refreshHz\":30,\"supportsH265\":false,\"lastUsed\":0}"
        let legacyScreen = try! JSONDecoder().decode(CarScreen.self, from: Data(legacy.utf8))
        assert(legacyScreen.nativeWidth == nil && legacyScreen.nativeHeight == nil)
        print("CarLife history and browser preferences isolated; native viewport ratio persisted; legacy screen decode passed")
    }
}
