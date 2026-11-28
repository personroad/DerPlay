import Foundation
@main struct Smoke {
    static func main() {
        var probe = DerPlayNetworkSessionProbe()
        assert(probe.begin() == nil)
        probe.start(expectedSSID: "A")
        let a = probe.begin()!
        assert(probe.begin() == nil)
        probe.start(expectedSSID: "B")
        let b = probe.begin()!
        assert(probe.complete(a, ssid: "A", currentAddress: "1") == .ignored)
        assert(probe.complete(b, ssid: "B", currentAddress: "2") == .eligible)
        assert(probe.complete(b, ssid: "B", currentAddress: "2") == .ignored)
        let c = probe.begin()!
        probe.setForeground(false)
        assert(probe.begin() == nil)
        probe.setForeground(true)
        assert(probe.complete(c, ssid: "B", currentAddress: "2") == .ignored)
        let d = probe.begin()!
        probe.cancel(d)
        let e = probe.begin()!
        probe.cancel(d)
        assert(probe.complete(e, ssid: "A", currentAddress: "2") == .wrongNetwork)
        let f = probe.begin()!
        assert(probe.complete(f, ssid: nil, currentAddress: "2") == .wait)
        let g = probe.begin()!
        assert(probe.complete(g, ssid: "B", currentAddress: nil) == .wait)
        let h = probe.begin()!
        probe.stop()
        assert(probe.complete(h, ssid: "B", currentAddress: "2") == .ignored)
        assert(probe.begin() == nil)
        print("Network session probe smoke passed")
    }
}
