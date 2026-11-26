import Foundation

@MainActor final class FakeAdapter: DerPlayOutputAdapter {
    let descriptor = DerPlayOutputDescriptor(id: "derplay.test", title: "Test", availability: .ready)
    var onTouch: ((DerPlayTouchEvent) -> Void)?
    func start() async throws {}
    func stop() async {}
    func sendVideo(_ frame: DerPlayVideoFrame) async throws {}
}
@main struct ExtensionSmoke {
    @MainActor static func main() throws {
        let catalog = DerPlayAdapterCatalog()
        for descriptor in DerPlayExtensionRegistry.planned { try catalog.register(descriptor) }
        do { _ = try catalog.make(id: "derplay.easyconnection"); fatalError("pending adapter enabled") }
        catch DerPlayAdapterError.unavailable {}
        let test = FakeAdapter().descriptor
        do { try catalog.register(test); fatalError("missing factory accepted") }
        catch DerPlayAdapterError.unavailable {}
        try catalog.register(test, factory: { FakeAdapter() })
        let adapter = try catalog.make(id: test.id)
        precondition(adapter.descriptor == test)
        do { try catalog.register(test, factory: { FakeAdapter() }); fatalError("duplicate accepted") }
        catch DerPlayAdapterError.duplicateID {}
        do { try catalog.register(.init(id: "upstream.test", title: "Test", availability: .development)); fatalError("foreign namespace accepted") }
        catch DerPlayAdapterError.invalidID {}
        precondition(DerPlayTouchEvent(x: 0.5, y: 1, phase: .began).isValid)
        precondition(!DerPlayTouchEvent(x: .nan, y: 0, phase: .moved).isValid)
        precondition(!DerPlayEndpoint(host: " ", port: 1).isValid)
        precondition(!DerPlayDisplayCapabilities(width: 0, height: 720, fps: 30).isValid)
        print("DerPlay extension smoke: PASS (registry, pending mode, factory, duplicate, namespace, input validation)")
    }
}
