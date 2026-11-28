import Foundation
@main struct Smoke {
    static func main() {
        var gate = DerPlayNetworkIdentityGate(expectedSSID: "Dashboard")
        assert(gate.evaluate(currentSSID: nil, address: "192.168.1.2", foreground: true) == .wait)
        assert(gate.evaluate(currentSSID: "Other", address: "192.168.1.2", foreground: true) == .wrongNetwork)
        assert(gate.evaluate(currentSSID: "dashboard", address: "192.168.1.2", foreground: true) == .wrongNetwork)
        assert(gate.evaluate(currentSSID: "Dashboard", address: nil, foreground: true) == .wait)
        assert(gate.evaluate(currentSSID: "Dashboard", address: "192.168.1.2", foreground: false) == .wait)
        assert(gate.evaluate(currentSSID: "Dashboard", address: "192.168.1.2", foreground: true) == .eligible)
        gate.stop()
        assert(gate.evaluate(currentSSID: "Dashboard", address: "192.168.1.2", foreground: true) == .cancelled)
        let empty = DerPlayNetworkIdentityGate(expectedSSID: "")
        assert(empty.evaluate(currentSSID: "Dashboard", address: "192.168.1.2", foreground: true) == .wait)
        print("Network identity gate smoke passed")
    }
}
