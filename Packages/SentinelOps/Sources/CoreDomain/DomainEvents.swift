import Foundation

/// An immutable, causally-versioned fact about an incident.
///
/// Events are appended to durable storage and never edited in place. Read models
/// are projections that may be rebuilt from this contract.
public struct IncidentEvent: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let incidentID: UUID
    public let actorID: String
    public let occurredAt: Date
    public let vectorClock: VectorClock
    public let type: EventType
    public let idempotencyKey: UUID

    public init(id: UUID = UUID(), incidentID: UUID, actorID: String, occurredAt: Date = Date(), vectorClock: VectorClock, type: EventType, idempotencyKey: UUID = UUID()) {
        self.id = id
        self.incidentID = incidentID
        self.actorID = actorID
        self.occurredAt = occurredAt
        self.vectorClock = vectorClock
        self.type = type
        self.idempotencyKey = idempotencyKey
    }
}

public enum EventType: Codable, Sendable, Hashable {
    case created
    case hazardDetected(confidence: Float)
    case fieldNoteAppended
    case resolved
}

/// Logical per-replica counters determine causal ordering without unreliable wall clocks.
public struct VectorClock: Codable, Sendable, Hashable {
    public private(set) var counters: [String: UInt64]
    public init(counters: [String: UInt64] = [:]) { self.counters = counters }

    public mutating func increment(replicaID: String) {
        counters[replicaID, default: 0] &+= 1
    }

    /// Returns the component-wise maximum after accepting a remote event.
    public func merge(with other: VectorClock) -> VectorClock {
        var merged = counters
        for (replica, counter) in other.counters {
            merged[replica] = max(merged[replica, default: 0], counter)
        }
        return VectorClock(counters: merged)
    }

    /// True only when neither clock causally dominates the other.
    public func isConflicting(with other: VectorClock) -> Bool {
        let replicas = Set(counters.keys).union(other.counters.keys)
        var hasGreater = false
        var hasLesser = false
        for replica in replicas {
            let local = counters[replica, default: 0]
            let remote = other.counters[replica, default: 0]
            hasGreater = hasGreater || local > remote
            hasLesser = hasLesser || local < remote
        }
        return hasGreater && hasLesser
    }
}

public protocol EventStore: Sendable {
    func append(_ events: [IncidentEvent]) async throws
    func unacknowledgedEvents(limit: Int) async throws -> [IncidentEvent]
    func acknowledge(eventIDs: [UUID]) async throws
}
