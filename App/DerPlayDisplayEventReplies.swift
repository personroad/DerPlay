import Foundation

/// Session-local response tracking for an explicitly requested display command.
/// Transport acceptance is not presentation confirmation. Never changes geometry.
struct DerPlayDisplayEventReplies {
    enum Outcome: Equatable { case accepted, rejected(Int), unsequencedResponse(Int), timedOut, channelClosed, writeFailed }
    typealias Completion = (Outcome) -> Void
    /// A fresh keyframe can help observe the result, but never confirms presentation.
    static func shouldRefreshVideo(after outcome: Outcome) -> Bool {
        outcome == .accepted || outcome == .unsequencedResponse(200)
    }
    private var pending: (sequence: Int, completion: Completion)?
    var isPending: Bool { pending != nil }

    mutating func register(sequence: Int, completion: @escaping Completion) -> Bool {
        guard sequence > 0, pending == nil else { return false }
        pending = (sequence, completion)
        return true
    }

    // Return a callback for invocation outside the mutating access, preventing reentrancy.
    mutating func resolve(sequence: Int, status: Int) -> (() -> Void)? {
        guard (200...599).contains(status), pending?.sequence == sequence else { return nil }
        return finish(sequence: sequence, outcome: status == 200 ? .accepted : .rejected(status))
    }

    mutating func resolveUnsequenced(candidate: Int, status: Int) -> (() -> Void)? {
        guard (200...599).contains(status), pending?.sequence == candidate else { return nil }
        return finish(sequence: candidate, outcome: .unsequencedResponse(status))
    }

    mutating func finish(sequence: Int? = nil, outcome: Outcome) -> (() -> Void)? {
        guard let current = pending, sequence == nil || current.sequence == sequence else { return nil }
        pending = nil
        return { current.completion(outcome) }
    }
}

/// Bounded ledger of ALL outgoing events, not only display commands.
/// A missing CSeq is only associated when exactly one request remains outstanding.
/// An ambiguous or overflowed ledger permanently disables inference for this channel.
struct DerPlayEventOrder {
    private var outstanding: [Int] = []
    private var uncertain = false
    mutating func invalidate() { uncertain = true; outstanding.removeAll() }
    mutating func sent(_ sequence: Int) {
        guard !uncertain else { return }
        guard outstanding.count < 128, !outstanding.contains(sequence) else {
            uncertain = true; outstanding.removeAll(); return
        }
        outstanding.append(sequence)
    }
    mutating func received(sequence: Int?, status: Int) -> Int? {
        guard (200...599).contains(status), !uncertain else { return nil }
        if let sequence {
            guard let index = outstanding.firstIndex(of: sequence) else {
                uncertain = true; outstanding.removeAll(); return nil
            }
            outstanding.remove(at: index); return nil
        }
        guard outstanding.count == 1 else {
            uncertain = true; outstanding.removeAll(); return nil
        }
        return outstanding.removeFirst()
    }
}

/// One diagnostic attempt per media session. A reply proves at most transport
/// acceptance. Keep touch suspended after an attempt until the session ends;
/// neither rejection nor timeout proves that the presentation did not change.
struct DerPlayDisplayProbe {
    private(set) var index: Int?
    private(set) var outcome: DerPlayDisplayEventReplies.Outcome?
    var blocksTouches: Bool { index != nil }
    mutating func begin(index: Int) -> Bool {
        guard self.index == nil, index > 0 else { return false }
        self.index = index
        return true
    }
    mutating func finish(_ result: DerPlayDisplayEventReplies.Outcome) {
        guard index != nil, outcome == nil else { return }
        outcome = result
    }
}

/// Passive, bounded diagnostic metadata; never used to decide protocol behavior.
struct DerPlayEventDiagnostics {
    private var commands: [Int: String] = [:]
    private var order: [Int] = []
    static func kind(_ type: String?) -> String {
        switch type {
        case "setNightMode", "updateViewArea", "forceKeyFrame", "hidSendReport", "requestSiri": return type!
        default: return "other"
        }
    }
    mutating func sent(sequence: Int, type: String?) -> String {
        let kind = Self.kind(type)
        if order.count == 128 { commands.removeValue(forKey: order.removeFirst()) }
        order.append(sequence); commands[sequence] = kind
        return kind
    }
    mutating func response(sequence: Int?, candidate: Int?, invalidSequence: Bool, status: Int) -> String {
        guard (200...599).contains(status) else { return "non-final" }
        let key = sequence ?? (invalidSequence ? nil : candidate)
        guard let key, let kind = commands.removeValue(forKey: key) else { return "unattributed" }
        order.removeAll { $0 == key }
        return "\(sequence == nil ? "tentative" : "exact") CSeq=\(key) type=\(kind)"
    }
    var pendingSummary: String {
        "pending=\(order.count) recent=" + order.suffix(4).map { "\($0):\(commands[$0] ?? "other")" }.joined(separator: ",")
    }
}
