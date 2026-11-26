import Foundation
import Security
import CryptoKit

/// Local import of legitimately obtained P-256 accessory identities. Local
/// key matching is not a certificate trust decision or accessory authorization.
enum DerPlayIdentityImport {
    struct Material: Codable {
        let chain: Data
        let leaf: Data
        let key: Data
        let format: String
        func identity() throws -> AccessoryIdentity {
            try AccessoryIdentity(certificateChain: chain, leafCertificate: leaf, privateKeyX963: key)
        }
    }
    enum Failure: LocalizedError {
        case selection, missingChain, missingKey, missingLeaf, file, format, mismatch, ambiguous, keychain(OSStatus)
        var errorDescription: String? {
            switch self {
            case .selection: return "请选择一组完整的两个或三个身份文件。"
            case .missingChain: return "缺少 DER PKCS#7 证书链文件。"
            case .missingKey: return "缺少支持的 P-256 私钥文件。"
            case .missingLeaf: return "X9.63 私钥需要同时选择 DER 叶证书文件。"
            case .file: return "无法读取身份文件，或文件超过 64 KB。"
            case .format: return "身份文件格式不受支持。需要 DER PKCS#7 证书链和 P-256 PKCS#8 私钥，或证书链、DER 叶证书和 X9.63 私钥。"
            case .mismatch: return "证书链中没有与私钥匹配的叶证书，或所选叶证书不在证书链中。"
            case .ambiguous: return "检测到重复文件或多个可能的身份，请只选择一组。"
            case .keychain(let status): return "本机 Keychain 操作失败（\(status)）。"
            }
        }
    }
    // The document picker imports local copies; do not coordinate the source
    // provider again. Keep the size bound and support scoped URLs if supplied.
    static func readCopiedFile(_ url: URL) throws -> Data {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            guard url.isFileURL else { throw Failure.file }
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true, let size = values.fileSize, (1...65_536).contains(size) else { throw Failure.file }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: 65_537) ?? Data()
            guard data.count == size, (try handle.read(upToCount: 1) ?? Data()).isEmpty else { throw Failure.file }
            return data
        } catch { throw Failure.file }
    }
    static func recognize(_ files: [Data]) throws -> Material {
        guard (2...3).contains(files.count) else { throw Failure.selection }
        guard Set(files).count == files.count else { throw Failure.ambiguous }
        var chain: Data?, certificates: [Data] = [], leaf: Data?, key: Data?, keyFormat: String?
        for data in files {
            guard (1...65_536).contains(data.count) else { throw Failure.file }
            if let entries = try? DerPlayIdentityDER.certificates(data) {
                guard chain == nil else { throw Failure.ambiguous }
                guard entries.allSatisfy({ SecCertificateCreateWithData(nil, $0 as CFData) != nil }) else { throw Failure.format }
                chain = data; certificates = entries
            } else if SecCertificateCreateWithData(nil, data as CFData) != nil {
                guard leaf == nil else { throw Failure.ambiguous }; leaf = data
            } else if let decoded = try? DerPlayIdentityDER.pkcs8(data), let parsed = try? P256.Signing.PrivateKey(rawRepresentation: decoded.scalar) {
                guard key == nil else { throw Failure.ambiguous }
                if let point = decoded.publicPoint {
                    guard point == parsed.publicKey.x963Representation || point == parsed.publicKey.compressedRepresentation else { throw Failure.format }
                }
                key = parsed.x963Representation; keyFormat = "PKCS#8"
            } else if data.count == 97, let parsed = try? P256.Signing.PrivateKey(x963Representation: data), parsed.x963Representation == data {
                guard key == nil else { throw Failure.ambiguous }
                key = data; keyFormat = "X9.63"
            } else { throw Failure.format }
        }
        guard let chain else { throw Failure.missingChain }
        guard let key, let keyFormat else { throw Failure.missingKey }
        if files.count == 2 {
            if keyFormat == "X9.63" { throw Failure.missingLeaf }
            guard leaf == nil, keyFormat == "PKCS#8" else { throw Failure.selection }
        } else {
            guard leaf != nil, keyFormat == "X9.63" else { throw Failure.selection }
        }
        let candidates = Array(Set(certificates)).filter { leaf == nil || $0 == leaf }
        let matches = candidates.filter { (try? AccessoryIdentity(certificateChain: chain, leafCertificate: $0, privateKeyX963: key)) != nil }
        guard !matches.isEmpty else { throw Failure.mismatch }
        guard matches.count == 1 else { throw Failure.ambiguous }
        return Material(chain: chain, leaf: matches[0], key: key, format: files.count == 2 ? "两文件 · PKCS#8" : "三文件 · X9.63")
    }
}

/// A single Keychain record makes replacement atomic. A cleared marker prevents
/// silently reactivating a previously bundled or legacy identity.
enum DerPlayIdentityVault {
    struct Record: Codable { let material: DerPlayIdentityImport.Material? }
    private static var query: [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: "com.derplay.app.mfi-identity", kSecAttrAccount: "identity-v1"]
    }
    static func read() throws -> Record? {
        var request = query; request[kSecReturnData] = true; request[kSecMatchLimit] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &value)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw DerPlayIdentityImport.Failure.keychain(status) }
        guard let data = value as? Data else { throw DerPlayIdentityImport.Failure.format }
        return try PropertyListDecoder().decode(Record.self, from: data)
    }
    static func write(_ record: Record) throws {
        var data = try PropertyListEncoder().encode(record)
        defer { data.resetBytes(in: 0..<data.count) }
        let changes: [CFString: Any] = [kSecValueData: data, kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        var status = SecItemUpdate(query as CFDictionary, changes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query; for (key, value) in changes { add[key] = value }
            status = SecItemAdd(add as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw DerPlayIdentityImport.Failure.keychain(status) }
    }
}
