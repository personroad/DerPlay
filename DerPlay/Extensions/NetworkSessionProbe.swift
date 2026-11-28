import Foundation

/// Value-state coordinator. Caller must serialize all calls on one executor.
/// No system Wi-Fi calls, timers, or connection side effects.
struct DerPlayNetworkSessionProbe {
    struct Ticket: Equatable { fileprivate let id: UUID }
    enum Result: Equatable { case ignored, wait, wrongNetwork, eligible }
    private var gate: DerPlayNetworkIdentityGate?
    private var pending: Ticket?
    private var foreground = false

    mutating func start(expectedSSID: String) {
        gate = DerPlayNetworkIdentityGate(expectedSSID: expectedSSID)
        pending = nil
        foreground = true
    }
    mutating func stop() { gate = nil; pending = nil; foreground = false }
    mutating func setForeground(_ value: Bool) {
        foreground = value
        if !value { pending = nil }
    }
    mutating func begin() -> Ticket? {
        guard gate != nil, foreground, pending == nil else { return nil }
        let ticket = Ticket(id: UUID())
        pending = ticket
        return ticket
    }
    mutating func cancel(_ ticket: Ticket) {
        if pending == ticket { pending = nil }
    }
    /// Address must be sampled at completion, not captured before asynchronous SSID lookup.
    mutating func complete(_ ticket: Ticket, ssid: String?, currentAddress: String?) -> Result {
        guard pending == ticket, foreground, let gate else { return .ignored }
        pending = nil
        switch gate.evaluate(currentSSID: ssid, address: currentAddress, foreground: foreground) {
        case .eligible: return .eligible
        case .wrongNetwork: return .wrongNetwork
        case .wait: return .wait
        case .cancelled: return .ignored
        }
    }
}
