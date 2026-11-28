import Foundation
import Dispatch

/// Offline candidate. All backend calls must use this executor exclusively.
/// Backend closures must not re-enter the executor or synchronously wait on its callers.
final class AudioSessionSerialExecutor: @unchecked Sendable {
    typealias Owner = AudioSessionOwnershipPolicy.Owner
    enum ExecutionError: Error { case reentrantBackendCall, pictureInPictureAlreadyOwned, ownerAlreadyOwned }
    enum ReleaseResult: Equatable, Sendable {
        case invalidToken, retainedByOtherOwners, idle(UUID), reentrantRejected
    }
    private let queueKey = DispatchSpecificKey<UInt8>()
    private let queue = DispatchQueue(label: "com.derplay.audio-session-candidate")
    private var policy = AudioSessionOwnershipPolicy()
    private var completedIdleTicket: UUID?
    private let activate: (Owner, Set<Owner>) throws -> Void
    private let deactivate: () throws -> Void

    convenience init(activate: @escaping () throws -> Void, deactivate: @escaping () throws -> Void) {
        self.init(activateForOwner: { _, _ in try activate() }, deactivate: deactivate)
    }

    /// The backend receives the requesting owner and all prospective live owners.
    /// This is needed for category/route decisions without reentering the executor.
    init(activateForOwner: @escaping (Owner, Set<Owner>) throws -> Void, deactivate: @escaping () throws -> Void) {
        self.activate = activateForOwner
        self.deactivate = deactivate
        queue.setSpecific(key: queueKey, value: 1)
    }

    /// A failed activation leaves existing ownership intact. The backend must
    /// handle partial activation errors; this executor cannot infer OS state.
    func acquire(_ owner: Owner) throws -> UUID {
        guard DispatchQueue.getSpecific(key: queueKey) == nil else { throw ExecutionError.reentrantBackendCall }
        return try queue.sync {
            try acquireOnQueue(owner)
        }
    }

    private func acquireOnQueue(_ owner: Owner) throws -> UUID {
        // Each logical owner must release its existing claim before reacquiring.
        if policy.contains(owner) {
            if owner == .pictureInPicture { throw ExecutionError.pictureInPictureAlreadyOwned }
            throw ExecutionError.ownerAlreadyOwned
        }
        try activate(owner, policy.activeOwners.union([owner]))
        return policy.acquire(owner)
    }

    /// Reactivate an existing claim without changing its token or ownership revision.
    /// Caller must first confirm that the system permits interruption recovery.
    /// A stale token never calls the activation backend.
    @discardableResult
    func reactivate(_ owner: Owner, token: UUID) throws -> Bool {
        guard DispatchQueue.getSpecific(key: queueKey) == nil else { throw ExecutionError.reentrantBackendCall }
        return try queue.sync { try reactivateOnQueue(owner, token: token) }
    }

    func reactivateAsync(_ owner: Owner, token: UUID) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do { continuation.resume(returning: try self.reactivateOnQueue(owner, token: token)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func reactivateOnQueue(_ owner: Owner, token: UUID) throws -> Bool {
        guard policy.owns(owner, token: token) else { return false }
        try activate(owner, policy.activeOwners)
        return true
    }

    private func releaseOnQueue(_ owner: Owner, token: UUID) -> ReleaseResult {
        guard policy.release(owner, token: token) else { return .invalidToken }
        if let ticket = policy.idleTicket { return .idle(ticket) }
        return .retainedByOtherOwners
    }

    func releaseDetailed(_ owner: Owner, token: UUID) -> ReleaseResult {
        guard DispatchQueue.getSpecific(key: queueKey) == nil else { return .reentrantRejected }
        return queue.sync { releaseOnQueue(owner, token: token) }
    }

    /// Compatibility interface. New callers should use the detailed result.
    func release(_ owner: Owner, token: UUID) -> UUID? {
        if case .idle(let ticket) = releaseDetailed(owner, token: token) { return ticket }
        return nil
    }

    /// Nonblocking submission; completion resumes outside the serial queue.
    /// Cancellation does not withdraw an already submitted operation.
    func acquireAsync(_ owner: Owner) async throws -> UUID {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try self.acquireOnQueue(owner))
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    func releaseAsync(_ owner: Owner, token: UUID) async -> ReleaseResult {
        await withCheckedContinuation { continuation in
            queue.async { continuation.resume(returning: self.releaseOnQueue(owner, token: token)) }
        }
    }

    func deactivateIfIdleAsync(ticket: UUID) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do { continuation.resume(returning: try self.deactivateOnQueue(ticket: ticket)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    /// Checks ownership and invokes the backend in the same serialized operation.
    /// Failed deactivation can be retried with the same ticket while still idle.
    @discardableResult
    func deactivateIfIdle(ticket: UUID) throws -> Bool {
        guard DispatchQueue.getSpecific(key: queueKey) == nil else { throw ExecutionError.reentrantBackendCall }
        return try queue.sync { try deactivateOnQueue(ticket: ticket) }
    }

    private func deactivateOnQueue(ticket: UUID) throws -> Bool {
        guard policy.permitsDeactivation(ticket: ticket), completedIdleTicket != ticket else { return false }
        try deactivate()
        completedIdleTicket = ticket
        return true
    }
}
