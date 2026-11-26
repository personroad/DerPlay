// DerPlay-owned lifecycle, independent of the upstream transport implementations.
import Foundation

@MainActor final class DerPlayExtensionSession {
    enum State: Equatable { case idle, discovering, starting, active, stopping }
    enum SessionError: Error, Equatable { case busy, inactive, invalidFrame }
    private(set) var state: State = .idle
    private var adapter: (any DerPlayOutputAdapter)?
    // No internal queue: producers must handle explicit backpressure.
    private var mediaTask: Task<Void, Error>?
    private var mediaToken: UUID?
    private var operationInFlight: Bool { mediaTask != nil }
    private var generation: UUID?
    private var discoveryTask: Task<[DerPlayEndpoint], Error>?
    private var startupTask: Task<DerPlayDisplayCapabilities?, Error>?
    private(set) var negotiatedDisplay: DerPlayDisplayCapabilities?
    var onTouch: ((DerPlayTouchEvent) -> Void)?

    // Cancel requests are cooperative. Adapters must implement bounded I/O
    // and observe Task cancellation; cleanup finishes before reuse.
    @discardableResult func cancelStartup() -> Bool {
        guard state == .starting, let startupTask else { return false }
        startupTask.cancel()
        return true
    }
    @discardableResult func cancelDiscovery() -> Bool {
        guard state == .discovering, let discoveryTask else { return false }
        discoveryTask.cancel()
        return true
    }
    // Discovery uses a separate adapter instance and never starts media routing.
    // The adapter must bound discovery I/O and support cooperative cancellation.
    func discover(id: String, catalog: DerPlayAdapterCatalog) async throws -> [DerPlayEndpoint] {
        guard state == .idle, !operationInFlight else { throw SessionError.busy }
        guard let candidate = try catalog.make(id: id) as? any DerPlayDiscoveryAdapter else {
            throw DerPlayAdapterError.unavailable
        }
        state = .discovering
        candidate.onTouch = nil
        let task = Task<[DerPlayEndpoint], Error> {
            try Task.checkCancellation()
            let endpoints = try await candidate.discover()
            try Task.checkCancellation()
            var result: [DerPlayEndpoint] = []
            // Bound the published list; preserve discovery order and normalize whitespace.
            for endpoint in endpoints {
                let normalized = DerPlayEndpoint(host: endpoint.host.trimmingCharacters(in: .whitespacesAndNewlines), port: endpoint.port)
                guard normalized.isValid, !result.contains(normalized) else { continue }
                result.append(normalized)
                if result.count == 64 { break }
            }
            return result
        }
        discoveryTask = task
        let outcome: Result<[DerPlayEndpoint], Error>
        do {
            outcome = .success(try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() }))
        } catch { outcome = .failure(error) }
        // Remain busy until cleanup completes, including on error and cancellation.
        state = .stopping
        candidate.onTouch = nil
        await candidate.stop()
        discoveryTask = nil
        state = .idle
        try Task.checkCancellation()
        guard !task.isCancelled else { throw CancellationError() }
        return try outcome.get()
    }
    func start(id: String, catalog: DerPlayAdapterCatalog, endpoint: DerPlayEndpoint? = nil) async throws {
        guard state == .idle, !operationInFlight else { throw SessionError.busy }
        if let endpoint, !endpoint.isValid { throw DerPlayAdapterError.invalidEndpoint }
        let candidate = try catalog.make(id: id)
        if endpoint != nil, !(candidate is any DerPlayNegotiatingAdapter) {
            throw DerPlayAdapterError.unavailable
        }
        negotiatedDisplay = nil
        state = .starting
        adapter = candidate
        let token = UUID()
        generation = token
        candidate.onTouch = { [weak self] event in
            guard let self, self.generation == token, self.state == .active, event.isValid else { return }
            self.onTouch?(event)
        }
        let task = Task<DerPlayDisplayCapabilities?, Error> {
            var negotiated: DerPlayDisplayCapabilities?
            try Task.checkCancellation()
            if let endpoint, let negotiating = candidate as? any DerPlayNegotiatingAdapter {
                let display = try await negotiating.negotiate(endpoint: endpoint)
                try Task.checkCancellation()
                guard display.isValid else { throw DerPlayAdapterError.invalidDisplay }
                negotiated = display
            }
            try await candidate.start()
            try Task.checkCancellation()
            return negotiated
        }
        startupTask = task
        defer { startupTask = nil }
        do {
            let display = try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
            try Task.checkCancellation()
            guard !task.isCancelled else { throw CancellationError() }
            negotiatedDisplay = display
            state = .active
        } catch {
            state = .stopping
            negotiatedDisplay = nil
            generation = nil
            candidate.onTouch = nil
            await candidate.stop()
            adapter = nil
            state = .idle
            throw error
        }
    }
    func stop() async throws {
        if state == .idle { return }
        guard state == .active, let adapter else { throw SessionError.busy }
        state = .stopping
        negotiatedDisplay = nil
        generation = nil
        adapter.onTouch = nil
        // Drain the single outstanding operation before touching transport resources.
        // Cancellation is cooperative; a real adapter must bound its I/O.
        if let task = mediaTask {
            task.cancel()
            _ = await task.result
        }
        mediaTask = nil
        mediaToken = nil
        await adapter.stop()
        self.adapter = nil
        state = .idle
    }
    private func transmit(_ operation: @escaping @MainActor () async throws -> Void) async throws {
        guard state == .active else { throw SessionError.inactive }
        guard !operationInFlight else { throw SessionError.busy }
        try Task.checkCancellation()
        let token = UUID()
        let task = Task<Void, Error> {
            try Task.checkCancellation()
            try await operation()
            try Task.checkCancellation()
        }
        mediaToken = token
        mediaTask = task
        defer {
            // A stopped session may have been replaced before this caller resumes.
            if mediaToken == token { mediaTask = nil; mediaToken = nil }
        }
        try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
        try Task.checkCancellation()
        guard !task.isCancelled, state == .active, mediaToken == token else { throw CancellationError() }
    }
    func sendVideo(_ frame: DerPlayVideoFrame) async throws {
        guard state == .active, let adapter else { throw SessionError.inactive }
        guard !operationInFlight else { throw SessionError.busy }
        guard !frame.annexB.isEmpty,
              frame.presentationTime.isFinite else { throw SessionError.invalidFrame }
        try await transmit { try await adapter.sendVideo(frame) }
    }
    func sendAudio(_ frame: DerPlayAudioFrame) async throws {
        guard state == .active, let adapter else { throw SessionError.inactive }
        guard !operationInFlight else { throw SessionError.busy }
        guard let audio = adapter as? any DerPlayAudioAdapter else { throw DerPlayAdapterError.unsupportedAudio }
        // Check PCM alignment without multiplying the channel count (which could overflow).
        guard frame.sampleRate > 0, frame.channels > 0, !frame.pcm.isEmpty,
              frame.pcm.count % 2 == 0, (frame.pcm.count / 2) % frame.channels == 0,
              frame.presentationTime.isFinite else { throw SessionError.invalidFrame }
        try await transmit { try await audio.sendAudio(frame) }
    }
}
