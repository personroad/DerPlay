import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif

final class UpdateStub: URLProtocol {
    static var responses: [String: (Int, Data)] = [:]
    static var requests: [String] = []
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let url = request.url!
        Self.requests.append(url.absoluteString)
        let (status, data) = Self.responses[url.absoluteString] ?? (404, Data())
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
struct UpdateSmoke {
    static func main() async throws {
        let base = "https://github.com/personroad/DerPlay/releases/download/v1.0.1-build13/"
        let api = "https://api.github.com/repos/personroad/DerPlay/releases/latest"
        let checksum = String(repeating: "a", count: 64)
        var manifest: [String: Any] = ["schemaVersion": 1, "product": "DerPlay", "platform": "ios",
            "version": "1.0.1", "build": 13, "minimumOSVersion": "16.4", "releaseTag": "v1.0.1-build13",
            "ipaName": "DerPlay-1.0.1-build13.ipa", "size": 100, "sha256": checksum, "notes": "Short summary"]
        var release: [String: Any] = ["id": 1, "tag_name": "v1.0.1-build13", "body": "Full release notes",
            "draft": false, "prerelease": false, "assets": [
                ["id": 2, "name": "DerPlay-1.0.1-build13.ipa", "size": 100, "browser_download_url": base + "DerPlay-1.0.1-build13.ipa"],
                ["id": 3, "name": "ios-update.json", "size": 800, "browser_download_url": base + "ios-update.json"]]]
        func publish() throws {
            UpdateStub.responses[api] = (200, try JSONSerialization.data(withJSONObject: release))
            UpdateStub.responses[base + "ios-update.json"] = (200, try JSONSerialization.data(withJSONObject: manifest))
        }
        try publish()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UpdateStub.self]
        let service = AppReleaseService(session: URLSession(configuration: configuration))
        let latest = try await service.latest()
        assert(latest.update?.notes == "Short summary" && latest.body == "Full release notes")
        assert(latest.ipa?.sha256 == checksum)
        assert(latest.update?.localizedNotes(english: true) == "Short summary")
        manifest["notesEn"] = "English summary"
        try publish()
        let bilingual = try await service.latest()
        assert(bilingual.update?.localizedNotes(english: true) == "English summary")
        assert(bilingual.update?.localizedNotes(english: false) == "Short summary")
        manifest["notesEn"] = "  \n "
        try publish()
        let blankEnglish = try await service.latest()
        assert(blankEnglish.update?.localizedNotes(english: true) == "Short summary")
        manifest.removeValue(forKey: "notesEn")
        try publish()
        UpdateStub.requests.removeAll()
        _ = try await service.latest()
        let suite = "DerPlay.UpdateSmoke." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let policy = AppUpdatePolicy(defaults: defaults)
        assert(policy.shouldOffer(latest, installedBuild: 12))
        assert(!policy.shouldOffer(latest, installedBuild: 13))
        assert(!policy.shouldOffer(latest, installedBuild: 14))
        var lowerVersion = latest
        lowerVersion.update = IOSUpdateMetadata(schemaVersion: 1, product: "DerPlay", platform: "ios", version: "0.1.0",
            build: 14, minimumOSVersion: "16.4", releaseTag: "v0.1.0-build14", ipaName: "DerPlay-1.0.1-build13.ipa", size: 100, sha256: checksum, notes: "Test")
        assert(policy.shouldOffer(lowerVersion, installedBuild: 13), "Only build controls ordering")
        policy.ignore(latest)
        assert(!policy.shouldOffer(latest, installedBuild: 12))
        assert(policy.shouldOffer(lowerVersion, installedBuild: 12), "Ignoring build 13 must not hide build 14")
        policy.succeeded(now: 100_000)
        assert(!policy.shouldCheck(now: 100_001))
        assert(policy.shouldCheck(now: 100_000 + 86400))
        _ = try await service.latest()
        assert(UpdateStub.requests.filter { $0 == base + "ios-update.json" }.count == 2)
        _ = try await service.latestTag()
        assert(UpdateStub.requests.filter { $0 == base + "ios-update.json" }.count == 2, "Browsing history must not count as checking")
        manifest["product"] = "CarWithin"
        try publish()
        do { _ = try await service.latest(); fatalError("Foreign product accepted") }
        catch ReleaseError.invalid {}
        manifest["product"] = "DerPlay"
        manifest["build"] = 14
        try publish()
        do { _ = try await service.latest(); fatalError("Mismatched build accepted") }
        catch ReleaseError.invalid {}
        manifest["build"] = 13
        manifest["size"] = 101
        try publish()
        do { _ = try await service.latest(); fatalError("Mismatched IPA size accepted") }
        catch ReleaseError.invalid {}
        release["assets"] = [["id": 2, "name": "DerPlay-1.0.1-build13.ipa", "size": 100, "browser_download_url": base + "DerPlay-1.0.1-build13.ipa"]]
        try publish()
        do { _ = try await service.latest(); fatalError("Missing manifest accepted") }
        catch ReleaseError.missingMetadata {}
        // History is initially non-downloadable until its own manifest passes validation.
        release["update"] = manifest // API must never supply trusted metadata directly.
        let raw = try AppReleaseService.decoder().decode(AppRelease.self, from: JSONSerialization.data(withJSONObject: release))
        assert(raw.update == nil && raw.ipa == nil)
        do { _ = try await service.verifiedRelease(raw); fatalError("Unverified history accepted") }
        catch ReleaseError.missingMetadata {}
        #if canImport(CryptoKit)
        let bytes = Data([0x50, 0x4b, 0x03, 0x04, 0x01, 0x02])
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        try bytes.write(to: file)
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let asset = AppRelease.Asset(id: 9, name: "DerPlay-1.0.1-build13.ipa", size: Int64(bytes.count), browser_download_url: URL(string: base + "DerPlay-1.0.1-build13.ipa")!, digest: "sha256:" + digest)
        try AppReleaseService.verify(file, asset: asset)
        try Data([0x50,0x4b,0x03,0x04,0x03,0x04]).write(to: file)
        do { try AppReleaseService.verify(file, asset: asset); fatalError("Wrong checksum accepted") }
        catch ReleaseError.checksum {}
        print("CryptoKit file verification passed")
        #endif
        print("JSON discovery, strict validation, build-only ordering, ignore and fetch-count checks passed")
    }
}
