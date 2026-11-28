import Foundation

/// Recovery eligibility only; SSID is not peer authentication.
struct DerPlayNetworkIdentityGate {
    enum Decision: Equatable { case wait, eligible, wrongNetwork, cancelled }
    private let expectedSSID: String
    private var stopped = false
    init(expectedSSID: String) { self.expectedSSID = expectedSSID }
    mutating func stop() { stopped = true }
    func evaluate(currentSSID: String?, address: String?, foreground: Bool) -> Decision {
        guard !stopped else { return .cancelled }
        guard foreground, !expectedSSID.isEmpty, let currentSSID, !currentSSID.isEmpty else { return .wait }
        guard currentSSID == expectedSSID else { return .wrongNetwork }
        guard let address, !address.isEmpty else { return .wait }
        return .eligible
    }
}
