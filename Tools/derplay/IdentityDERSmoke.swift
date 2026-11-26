import Foundation

// Only OpenSSL-generated temporary test identities are used. Nothing is bundled.
@main struct IdentityDERSmoke {
    static func main() throws {
        let urls = CommandLine.arguments.dropFirst().map { URL(fileURLWithPath: $0) }
        let files = try urls.map { try Data(contentsOf: $0) }
        let chain = files[0], leaf = files[1], fullKey = files[2], minimalKey = files[3]
        let certificates = try DerPlayIdentityDER.certificates(chain)
        let full = try DerPlayIdentityDER.pkcs8(fullKey)
        let minimal = try DerPlayIdentityDER.pkcs8(minimalKey)
        precondition(certificates.contains(leaf))
        precondition(full.scalar.count == 32 && minimal.scalar == full.scalar)
        precondition(minimal.publicPoint == nil)
        for bad in [Data(), Data(chain.dropLast()), chain + Data([0]), Data([0x30,0x80,0,0]), Data([0x30,0x81,0x00])] {
            precondition((try? DerPlayIdentityDER.certificates(bad)) == nil)
        }
        for bad in [Data(), Data(fullKey.dropLast()), fullKey + Data([0]), leaf] {
            precondition((try? DerPlayIdentityDER.pkcs8(bad)) == nil)
        }
        print("Identity DER PASS: PKCS#7 extraction, standard/minimal PKCS#8, malformed and trailing bytes")
    }
}
