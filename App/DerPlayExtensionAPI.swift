// DerPlay-owned boundary; no dependencies on upstream receiver types.
import Foundation

struct DerPlayOutputDescriptor: Equatable {
    let id: String
    let title: String
    let availability: Availability
    enum Availability: Equatable { case development, ready }
}

struct DerPlayVideoFrame {
    let annexB: Data
    let presentationTime: TimeInterval
    let isKeyFrame: Bool
}
struct DerPlayAudioFrame {
    let pcm: Data
    let sampleRate: Int
    let channels: Int
    let presentationTime: TimeInterval
    // Signed 16-bit little-endian interleaved PCM.
}
struct DerPlayTouchEvent {
    enum Phase { case began, moved, ended, cancelled }
    let x: Double
    let y: Double
    let phase: Phase
    var isValid: Bool { x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y) }
}
struct DerPlayDisplayCapabilities: Equatable {
    let width: Int
    let height: Int
    let fps: Int
    var isValid: Bool { width > 0 && height > 0 && fps > 0 }
}
struct DerPlayEndpoint: Equatable {
    let host: String
    let port: UInt16
    var isValid: Bool { !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && port != 0 }
}
enum DerPlayAdapterError: Error, Equatable {
    case unavailable, duplicateID, invalidID, invalidEndpoint, invalidDisplay, unsupportedAudio
}
// Implementations must serialize transport operations, bound network I/O and observe cancellation.
// send methods return only after the operation is complete; do not enqueue unbounded work.
// The common session has no artificial media payload or channel-count ceiling.
// Each concrete adapter must validate its protocol-defined framing, negotiated limits,
// and integer representability before encoding or sending; never truncate to fit.
// Session backpressure is explicit (busy); callers must handle dropped video dependency chains
// by requesting a new keyframe before resuming inter-frame delivery.
@MainActor protocol DerPlayOutputAdapter: AnyObject {
    var descriptor: DerPlayOutputDescriptor { get }
    func start() async throws
    func stop() async
    func sendVideo(_ frame: DerPlayVideoFrame) async throws
    var onTouch: ((DerPlayTouchEvent) -> Void)? { get set }
}
@MainActor protocol DerPlayAudioAdapter: DerPlayOutputAdapter {
    func sendAudio(_ frame: DerPlayAudioFrame) async throws
}
@MainActor protocol DerPlayDiscoveryAdapter: DerPlayOutputAdapter {
    func discover() async throws -> [DerPlayEndpoint]
}
@MainActor protocol DerPlayNegotiatingAdapter: DerPlayOutputAdapter {
    func negotiate(endpoint: DerPlayEndpoint) async throws -> DerPlayDisplayCapabilities
}

// Registry is deliberately separate from UI and upstream enums. Registration alone does
// not enable a menu entry: a future session bridge must also supply actual routing.
@MainActor final class DerPlayAdapterCatalog {
    typealias Factory = @MainActor () -> any DerPlayOutputAdapter
    private var factories: [String: Factory] = [:]
    private(set) var descriptors: [DerPlayOutputDescriptor] = []
    func register(_ descriptor: DerPlayOutputDescriptor, factory: Factory? = nil) throws {
        guard descriptor.id.hasPrefix("derplay."), descriptor.id.count > 8 else { throw DerPlayAdapterError.invalidID }
        guard !descriptors.contains(where: { $0.id == descriptor.id }) else { throw DerPlayAdapterError.duplicateID }
        guard descriptor.availability != .ready || factory != nil else { throw DerPlayAdapterError.unavailable }
        descriptors.append(descriptor)
        if let factory { factories[descriptor.id] = factory }
    }
    func make(id: String) throws -> any DerPlayOutputAdapter {
        guard let descriptor = descriptors.first(where: { $0.id == id }), descriptor.availability == .ready,
              let factory = factories[id] else { throw DerPlayAdapterError.unavailable }
        let adapter = factory()
        guard adapter.descriptor == descriptor else { throw DerPlayAdapterError.unavailable }
        return adapter
    }
}

enum DerPlayExtensionRegistry {
    static let apiVersion = 2
    static let planned: [DerPlayOutputDescriptor] = [
        .init(id: "derplay.easyconnection", title: "亿连 Easy Connect", availability: .development),
        .init(id: "derplay.iccoa.direct", title: "Carlink", availability: .development)
    ]
}
