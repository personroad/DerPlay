import Foundation
import CryptoKit

@main struct IdentityImportSmoke {
    static func main() throws {
        let files = try CommandLine.arguments.dropFirst().map { try DerPlayIdentityImport.readCopiedFile(URL(fileURLWithPath: $0)) }
        let chain = files[0], leaf = files[1], pkcs8 = files[2], minimal = files[3], otherKey = files[4]
        let material = try DerPlayIdentityImport.recognize([pkcs8, chain])
        let minimalMaterial = try DerPlayIdentityImport.recognize([chain, minimal])
        let three = try DerPlayIdentityImport.recognize([leaf, material.key, chain])
        precondition(material.leaf == leaf && three.leaf == leaf && minimalMaterial.key == material.key)
        precondition(three.key == material.key)
        for batch in [[chain, pkcs8], [minimal, chain]] {
            let candidate = try DerPlayIdentityImport.recognize(batch)
            precondition(candidate.leaf == leaf && candidate.key == material.key)
        }
        for batch in [[chain, leaf, material.key], [chain, material.key, leaf], [leaf, chain, material.key], [material.key, chain, leaf], [material.key, leaf, chain]] {
            let candidate = try DerPlayIdentityImport.recognize(batch)
            precondition(candidate.leaf == leaf && candidate.key == material.key)
        }
        _ = try material.identity()
        _ = try three.identity()
        for bad in [[chain], [chain, chain], [chain, otherKey], [chain, material.key], [chain, leaf, pkcs8], [chain, Data([1,2,3])], [chain, leaf, Data(repeating: 0, count: 97)]] {
            precondition((try? DerPlayIdentityImport.recognize(bad)) == nil)
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        for size in [0, 65_537] {
            let url = temp.appendingPathComponent("test-\(size)")
            try Data(repeating: 0, count: size).write(to: url)
            precondition((try? DerPlayIdentityImport.readCopiedFile(url)) == nil)
        }
        precondition((try? DerPlayIdentityImport.readCopiedFile(temp)) == nil)
        print("Identity import PASS: order-independent two/three files, local key matching, wrong key and invalid selection rejection")
    }
}
