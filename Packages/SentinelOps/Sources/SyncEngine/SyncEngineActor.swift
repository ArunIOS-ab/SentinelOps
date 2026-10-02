import CoreDomain
import Foundation

public struct SyncRequest: Sendable {
    public let event: IncidentEvent
    public let idempotencyKey: String
    public init(event: IncidentEvent, idempotencyKey: String) {
        self.event = event
        self.idempotencyKey = idempotencyKey
    }
}

public protocol SyncTransport: Sendable {
    func upload(_ request: SyncRequest) async throws
}

/// Serializes queue state. I/O runs in child tasks; durable acknowledgement
/// returns to this actor, preventing races with a concurrent flush.
public actor SyncEngineActor {
    private let eventStore: any EventStore
    private let transport: any SyncTransport
    private var inFlightEventIDs = Set<UUID>()

    public init(eventStore: any EventStore, transport: any SyncTransport) {
        self.eventStore = eventStore
        self.transport = transport
    }

    /// Persists before scheduling work so process termination cannot lose a command.
    public func enqueue(_ event: IncidentEvent) async throws {
        try await eventStore.append([event])
    }

    /// Cancellation leaves every unacknowledged event durable for a later retry.
    public func flush(limit: Int = 20) async throws {
        let candidates = try await eventStore.unacknowledgedEvents(limit: limit).filter { !inFlightEventIDs.contains($0.id) }
        for event in candidates { inFlightEventIDs.insert(event.id) }
        defer { for event in candidates { inFlightEventIDs.remove(event.id) } }

        let succeeded = await withTaskGroup(of: UUID?.self, returning: [UUID].self) { group in
            for event in candidates {
                group.addTask { [transport] in
                    guard !Task.isCancelled else { return nil }
                    do {
                        try await transport.upload(SyncRequest(event: event, idempotencyKey: Self.idempotencyHeader(for: event)))
                        return event.id
                    } catch {
                        return nil
                    }
                }
            }
            var acknowledged: [UUID] = []
            for await eventID in group {
                guard !Task.isCancelled else { group.cancelAll(); break }
                if let eventID { acknowledged.append(eventID) }
            }
            return acknowledged
        }

        guard !Task.isCancelled, !succeeded.isEmpty else { return }
        try await eventStore.acknowledge(eventIDs: succeeded)
    }

    /// Stable across retries; inject a transport that writes this to the HTTP header.
    public nonisolated static func idempotencyHeader(for event: IncidentEvent) -> String {
        "\(event.incidentID.uuidString.lowercased()):\(event.idempotencyKey.uuidString.lowercased())"
    }
}
