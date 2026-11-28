import Foundation

/// Offline candidate. Ownership and AVAudioSession operations must eventually
/// be serialized on one executor; this value alone cannot enforce that.
struct AudioSessionOwnershipPolicy {
    enum Owner: Hashable { case stream(UUID), keepAlive, pictureInPicture }
    private var claims: [Owner: UUID] = [:]
    private var revision = UUID()
    mutating func acquire(_ owner: Owner) -> UUID {
        let token = UUID()
        claims[owner] = token
        revision = UUID()
        return token
    }
    @discardableResult
    mutating func release(_ owner: Owner, token: UUID) -> Bool {
        guard claims[owner] == token else { return false }
        claims.removeValue(forKey: owner)
        revision = UUID()
        return true
    }
    func owns(_ owner: Owner, token: UUID) -> Bool { claims[owner] == token }
    func contains(_ owner: Owner) -> Bool { claims[owner] != nil }
    var activeOwners: Set<Owner> { Set(claims.keys) }
    var idleTicket: UUID? { claims.isEmpty ? revision : nil }
    func permitsDeactivation(ticket: UUID) -> Bool {
        claims.isEmpty && revision == ticket
    }
}
