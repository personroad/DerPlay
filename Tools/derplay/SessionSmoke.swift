import Foundation
@MainActor final class SessionFake: DerPlayAudioAdapter, DerPlayNegotiatingAdapter, DerPlayDiscoveryAdapter {
    let descriptor = DerPlayOutputDescriptor(id: "derplay.sessiontest", title: "Test", availability: .ready)
    var onTouch: ((DerPlayTouchEvent) -> Void)?
    var fail = false
    var delayStart = false
    var enteredStart = false
    var display = DerPlayDisplayCapabilities(width: 1280, height: 720, fps: 30)
    var negotiatedEndpoints: [DerPlayEndpoint] = []
    var delayNegotiation = false
    var discoveryResults: [DerPlayEndpoint] = []
    var delayDiscovery = false
    var failDiscovery = false
    var enteredDiscovery = false
    func discover() async throws -> [DerPlayEndpoint] {
        enteredDiscovery = true
        if delayDiscovery { try await Task.sleep(nanoseconds: 30_000_000_000) }
        if failDiscovery { throw DerPlayAdapterError.unavailable }
        return discoveryResults
    }
    var stops = 0
    var videos = 0
    var audios = 0
    func start() async throws {
        enteredStart = true
        if fail { throw DerPlayAdapterError.unavailable }
        if delayStart { try await Task.sleep(nanoseconds: 30_000_000_000) }
    }
    func negotiate(endpoint: DerPlayEndpoint) async throws -> DerPlayDisplayCapabilities {
        negotiatedEndpoints.append(endpoint)
        if delayNegotiation { try await Task.sleep(nanoseconds: 30_000_000_000) }
        return display
    }
    var delayMedia = false
    var mediaEntered = false
    var mediaActive = false
    var failMedia = false
    func stop() async { precondition(!mediaActive); stops += 1 }
    func sendVideo(_ frame: DerPlayVideoFrame) async throws {
        mediaEntered = true; mediaActive = true
        defer { mediaActive = false }
        if delayMedia { try await Task.sleep(nanoseconds: 30_000_000_000) }
        if failMedia { throw DerPlayAdapterError.unavailable }
        videos += 1
    }
    func sendAudio(_ frame: DerPlayAudioFrame) async throws {
        mediaEntered = true; mediaActive = true
        defer { mediaActive = false }
        if delayMedia { try await Task.sleep(nanoseconds: 30_000_000_000) }
        if failMedia { throw DerPlayAdapterError.unavailable }
        audios += 1
    }
}
@main struct SessionSmoke {
    @MainActor static func main() async throws {
        let adapter = SessionFake(), catalog = DerPlayAdapterCatalog(), session = DerPlayExtensionSession()
        try catalog.register(adapter.descriptor, factory: { adapter })
        var touches = 0
        session.onTouch = { _ in touches += 1 }
        adapter.fail = true
        do { try await session.start(id: adapter.descriptor.id, catalog: catalog); fatalError("start failure ignored") }
        catch DerPlayAdapterError.unavailable {}
        precondition(session.state == .idle && adapter.stops == 1 && adapter.onTouch == nil)
        adapter.fail = false
        try await session.start(id: adapter.descriptor.id, catalog: catalog)
        precondition(session.state == .active)
        do { try await session.start(id: adapter.descriptor.id, catalog: catalog); fatalError("duplicate start") }
        catch DerPlayExtensionSession.SessionError.busy {}
        adapter.onTouch?(.init(x: 0.2, y: 0.8, phase: .began))
        adapter.onTouch?(.init(x: -1, y: 0.8, phase: .began))
        precondition(touches == 1)
        try await session.sendVideo(.init(annexB: Data([0,0,0,1,0x65]), presentationTime: 0, isKeyFrame: true))
        try await session.sendAudio(.init(pcm: Data([0,0,0,0]), sampleRate: 48000, channels: 2, presentationTime: 0))
        precondition(adapter.videos == 1 && adapter.audios == 1)
        do { try await session.sendAudio(.init(pcm: Data([0]), sampleRate: 48000, channels: 2, presentationTime: 0)); fatalError("invalid audio accepted") }
        catch DerPlayExtensionSession.SessionError.invalidFrame {}
        let staleTouch = adapter.onTouch
        try await session.stop()
        try await session.stop()
        precondition(session.state == .idle && adapter.stops == 2 && adapter.onTouch == nil)
        do { try await session.sendVideo(.init(annexB: Data([1]), presentationTime: 0, isKeyFrame: false)); fatalError("inactive send") }
        catch DerPlayExtensionSession.SessionError.inactive {}
        try await session.start(id: adapter.descriptor.id, catalog: catalog)
        staleTouch?(.init(x: 0.5, y: 0.5, phase: .began))
        precondition(touches == 1, "stale session callback accepted")
        adapter.onTouch?(.init(x: 0.5, y: 0.5, phase: .began))
        precondition(touches == 2)
        try await session.stop()
        adapter.delayStart = true
        adapter.enteredStart = false
        let pending = Task { try await session.start(id: adapter.descriptor.id, catalog: catalog) }
        while !adapter.enteredStart { await Task.yield() }
        precondition(session.cancelStartup())
        do { try await pending.value; fatalError("cancel ignored") }
        catch is CancellationError {}
        precondition(session.state == .idle && adapter.onTouch == nil && adapter.stops == 4)
        precondition(!session.cancelStartup())
        adapter.enteredStart = false
        let callerCancelled = Task { try await session.start(id: adapter.descriptor.id, catalog: catalog) }
        while !adapter.enteredStart { await Task.yield() }
        callerCancelled.cancel()
        do { try await callerCancelled.value; fatalError("caller cancel ignored") }
        catch is CancellationError {}
        precondition(session.state == .idle && adapter.stops == 5)
        adapter.delayStart = false
        try await session.start(id: adapter.descriptor.id, catalog: catalog)
        try await session.stop()
        let endpoint = DerPlayEndpoint(host: "receiver.local", port: 1234)
        try await session.start(id: adapter.descriptor.id, catalog: catalog, endpoint: endpoint)
        precondition(session.negotiatedDisplay == adapter.display && adapter.negotiatedEndpoints == [endpoint])
        try await session.stop()
        precondition(session.negotiatedDisplay == nil)
        do { try await session.start(id: adapter.descriptor.id, catalog: catalog, endpoint: .init(host: " ", port: 0)); fatalError("invalid endpoint accepted") }
        catch DerPlayAdapterError.invalidEndpoint {}
        precondition(session.state == .idle && adapter.negotiatedEndpoints.count == 1)
        adapter.display = .init(width: 0, height: 720, fps: 30)
        adapter.enteredStart = false
        do { try await session.start(id: adapter.descriptor.id, catalog: catalog, endpoint: endpoint); fatalError("invalid display accepted") }
        catch DerPlayAdapterError.invalidDisplay {}
        precondition(session.state == .idle && session.negotiatedDisplay == nil && !adapter.enteredStart && adapter.onTouch == nil)
        adapter.display = .init(width: 720, height: 1280, fps: 30)
        adapter.delayNegotiation = true
        let negotiation = Task { try await session.start(id: adapter.descriptor.id, catalog: catalog, endpoint: endpoint) }
        while adapter.negotiatedEndpoints.count < 3 { await Task.yield() }
        precondition(session.cancelStartup())
        do { try await negotiation.value; fatalError("negotiation cancellation ignored") }
        catch is CancellationError {}
        precondition(session.state == .idle && session.negotiatedDisplay == nil && adapter.onTouch == nil)
        adapter.delayNegotiation = false
        try await session.start(id: adapter.descriptor.id, catalog: catalog, endpoint: endpoint)
        precondition(session.negotiatedDisplay == adapter.display)
        try await session.stop()
        let beforeDiscovery = adapter.stops
        adapter.discoveryResults = [.init(host: " receiver.local ", port: 1234), endpoint, .init(host: " ", port: 10), .init(host: "bad", port: 0)]
        adapter.discoveryResults += (0..<100).map { .init(host: "device-\($0).local", port: 1234) }
        let found = try await session.discover(id: adapter.descriptor.id, catalog: catalog)
        precondition(found.count == 64 && found.first == endpoint && found.last?.host == "device-62.local")
        precondition(session.state == .idle && adapter.stops == beforeDiscovery + 1 && session.negotiatedDisplay == nil)
        adapter.failDiscovery = true
        do { _ = try await session.discover(id: adapter.descriptor.id, catalog: catalog); fatalError("discovery failure ignored") }
        catch DerPlayAdapterError.unavailable {}
        precondition(session.state == .idle && adapter.stops == beforeDiscovery + 2)
        adapter.failDiscovery = false
        adapter.delayDiscovery = true
        adapter.enteredDiscovery = false
        let scan = Task { try await session.discover(id: adapter.descriptor.id, catalog: catalog) }
        while !adapter.enteredDiscovery { await Task.yield() }
        do { try await session.start(id: adapter.descriptor.id, catalog: catalog); fatalError("start during discovery") }
        catch DerPlayExtensionSession.SessionError.busy {}
        do { _ = try await session.discover(id: adapter.descriptor.id, catalog: catalog); fatalError("parallel discovery") }
        catch DerPlayExtensionSession.SessionError.busy {}
        precondition(session.cancelDiscovery())
        do { _ = try await scan.value; fatalError("discovery cancel ignored") }
        catch is CancellationError {}
        precondition(session.state == .idle && adapter.stops == beforeDiscovery + 3 && !session.cancelDiscovery())
        adapter.enteredDiscovery = false
        let callerScan = Task { try await session.discover(id: adapter.descriptor.id, catalog: catalog) }
        while !adapter.enteredDiscovery { await Task.yield() }
        callerScan.cancel()
        do { _ = try await callerScan.value; fatalError("caller discovery cancel ignored") }
        catch is CancellationError {}
        precondition(session.state == .idle && adapter.stops == beforeDiscovery + 4)
        adapter.delayDiscovery = false
        try await session.start(id: adapter.descriptor.id, catalog: catalog, endpoint: found[0])
        try await session.stop()
        let video = DerPlayVideoFrame(annexB: Data([0,0,0,1,0x65]), presentationTime: 0, isKeyFrame: true)
        let audio = DerPlayAudioFrame(pcm: Data([0,0,0,0]), sampleRate: 48000, channels: 2, presentationTime: 0)
        try await session.start(id: adapter.descriptor.id, catalog: catalog)
        adapter.delayMedia = true; adapter.mediaEntered = false
        let sending = Task { try await session.sendVideo(video) }
        while !adapter.mediaEntered { await Task.yield() }
        do { try await session.sendAudio(audio); fatalError("parallel audio accepted") }
        catch DerPlayExtensionSession.SessionError.busy {}
        do { try await session.sendVideo(video); fatalError("parallel video accepted") }
        catch DerPlayExtensionSession.SessionError.busy {}
        let beforeMediaStop = adapter.stops
        try await session.stop()
        precondition(session.state == .idle && adapter.stops == beforeMediaStop + 1 && !adapter.mediaActive)
        do { try await sending.value; fatalError("stop did not cancel media") }
        catch is CancellationError {}
        try await session.start(id: adapter.descriptor.id, catalog: catalog)
        adapter.mediaEntered = false
        let audioSending = Task { try await session.sendAudio(audio) }
        while !adapter.mediaEntered { await Task.yield() }
        audioSending.cancel()
        do { try await audioSending.value; fatalError("caller media cancellation ignored") }
        catch is CancellationError {}
        precondition(session.state == .active && !adapter.mediaActive)
        adapter.delayMedia = false; adapter.failMedia = true
        do { try await session.sendVideo(video); fatalError("media failure ignored") }
        catch DerPlayAdapterError.unavailable {}
        adapter.failMedia = false
        try await session.sendVideo(video)
        try await session.sendAudio(audio)
        // A valid common-layer payload larger than the former arbitrary ceilings reaches the adapter.
        let previousVideos = adapter.videos, previousAudios = adapter.audios
        var largeVideo = Data([0, 0, 0, 1, 0x65])
        largeVideo.append(Data(repeating: 0x55, count: 9 * 1024 * 1024))
        try await session.sendVideo(.init(annexB: largeVideo, presentationTime: 0, isKeyFrame: true))
        try await session.sendAudio(.init(pcm: Data(count: 300 * 1024), sampleRate: 48000, channels: 2, presentationTime: 0))
        try await session.sendAudio(.init(pcm: Data(count: 20), sampleRate: 48000, channels: 10, presentationTime: 0))
        precondition(adapter.videos == previousVideos + 1 && adapter.audios == previousAudios + 2)
        for channels in [0, -1, Int.max] {
            do { try await session.sendAudio(.init(pcm: Data(count: 4), sampleRate: 48000, channels: channels, presentationTime: 0)); fatalError("invalid PCM accepted") }
            catch DerPlayExtensionSession.SessionError.invalidFrame {}
        }
        do { try await session.sendVideo(.init(annexB: Data(), presentationTime: 0, isKeyFrame: true)); fatalError("empty video accepted") }
        catch DerPlayExtensionSession.SessionError.invalidFrame {}
        try await session.stop()
        print("DerPlay media smoke: PASS (cross-media backpressure, stop cancellation and drain, caller cancellation, send failure recovery, protocol-owned payload limits, PCM alignment, reuse)")
        print("DerPlay discovery smoke: PASS (filter, deduplicate, cap, failure, exclusivity, cancellation, cleanup, reuse)")
        print("DerPlay negotiation smoke: PASS (explicit endpoint, invalid endpoint/display, cancellation, cleanup, reuse)")
        print("DerPlay session smoke: PASS (failure cleanup, start, duplicate start, touch validation, video/audio routing, invalid PCM, stop, inactive send, stale callback rejection, explicit and caller cancellation, restart)")
    }
}
