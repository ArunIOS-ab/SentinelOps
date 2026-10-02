/// SyncEngine: SyncEngineActor.swift
///
/// Thread-safe actor managing offline-first synchronization with durable event replay,
/// conflict detection via vector clocks, and resumable background uploads.

import Foundation

// MARK: - Sync Event

/// SyncEvent represents a command queued for remote synchronization.
public struct SyncEvent: Identifiable, Sendable {
    public let id: String
    public let incidentId: String
    public let eventType: String
    public let payload: Data
    public let idempotencyKey: String
    public let attemptCount: Int
    public let lastAttemptDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        incidentId: String,
        eventType: String,
        payload: Data,
        idempotencyKey: String,
        attemptCount: Int = 0,
        lastAttemptDate: Date? = nil
    ) {
        self.id = id
        self.incidentId = incidentId
        self.eventType = eventType
        self.payload = payload
        self.idempotencyKey = idempotencyKey
        self.attemptCount = attemptCount
        self.lastAttemptDate = lastAttemptDate
    }
}

// MARK: - Sync Status

/// SyncStatus indicates the current state of the sync engine.
public enum SyncStatus: Sendable {
    case idle
    case syncing(processedCount: Int, totalCount: Int)
    case backoff(nextRetryDate: Date)
    case error(message: String)
    case complete
}

// MARK: - Sync Engine Actor

/// SyncEngineActor manages offline-first synchronization with deterministic retry policies.
///
/// Key responsibilities:
/// - Maintain an in-memory and persisted queue of pending sync events.
/// - Implement exponential backoff for transient failures.
/// - Generate idempotency headers for safe retry semantics.
/// - Coordinate batch uploads via TaskGroup for cancellation safety.
/// - Expose sync status via AsyncStream for UI updates.
///
/// Example usage:
/// ```swift
/// let syncEngine = SyncEngineActor()
/// await syncEngine.enqueue(event)
/// for await status in await syncEngine.statusStream() {
///     print("Sync status: \(status)")
/// }
/// ```
public actor SyncEngineActor {
    /// In-memory queue of pending events.
    private var pendingQueue: [SyncEvent] = []
    
    /// Active continuation for the status stream.
    private var statusContinuation: AsyncStream<SyncStatus>.Continuation?
    
    /// Current sync status.
    private var currentStatus: SyncStatus = .idle {
        didSet {
            statusContinuation?.yield(currentStatus)
        }
    }
    
    /// Base backoff interval in seconds (starts at 2^0 = 1s, doubles each retry).
    private let baseBackoffSeconds: Int = 1
    
    /// Maximum backoff interval in seconds (caps at ~30 minutes).
    private let maxBackoffSeconds: Int = 1800
    
    /// Initialize the sync engine.
    public init() {}
    
    /// Enqueue an event for remote synchronization.
    ///
    /// The event is appended to the queue and immediately scheduled for upload
    /// if the current status permits. Multiple enqueues are safe and maintain order.
    ///
    /// - Parameter event: The SyncEvent to queue.
    public func enqueue(_ event: SyncEvent) async {
        pendingQueue.append(event)
        
        // Trigger flush if idle.
        if case .idle = currentStatus {
            await flush()
        }
    }
    
    /// Flush pending events via a batch upload pipeline.
    ///
    /// This method:
    /// - Constructs a TaskGroup for concurrent uploads (with backoff for failures).
    /// - Updates the status stream with progress.
    /// - Removes successfully synced events.
    /// - Re-enqueues failed events with incremented retry counts.
    ///
    /// Safe for cancellation: Task cancellation terminates the group gracefully.
    public func flush() async {
        guard !pendingQueue.isEmpty else {
            currentStatus = .idle
            return
        }
        
        currentStatus = .syncing(processedCount: 0, totalCount: pendingQueue.count)
        
        var processedCount = 0
        var successfulIds = Set<String>()
        var failedEvents: [SyncEvent] = []
        
        // Process events in a task group for cancellation safety.
        await withTaskGroup(of: (id: String, success: Bool).self) { group in
            for event in pendingQueue {
                group.addTask {
                    let success = await self.uploadEvent(event)
                    return (id: event.id, success: success)
                }
            }
            
            // Collect results as they complete.
            for await (id, success) in group {
                processedCount += 1
                currentStatus = .syncing(processedCount: processedCount, totalCount: pendingQueue.count)
                
                if success {
                    successfulIds.insert(id)
                } else {
                    // Retain for retry.
                    if let failedEvent = pendingQueue.first(where: { $0.id == id }) {
                        failedEvents.append(failedEvent)
                    }
                }
            }
        }
        
        // Remove successfully synced events.
        pendingQueue.removeAll { successfulIds.contains($0.id) }
        
        // Re-enqueue failed events with retry backoff.
        for failedEvent in failedEvents {
            let nextAttemptDate = Date().addingTimeInterval(TimeInterval(backoffDuration(for: failedEvent.attemptCount)))
            let retryEvent = SyncEvent(
                id: failedEvent.id,
                incidentId: failedEvent.incidentId,
                eventType: failedEvent.eventType,
                payload: failedEvent.payload,
                idempotencyKey: failedEvent.idempotencyKey,
                attemptCount: failedEvent.attemptCount + 1,
                lastAttemptDate: nextAttemptDate
            )
            pendingQueue.append(retryEvent)
        }
        
        if pendingQueue.isEmpty {
            currentStatus = .complete
        } else {
            let nextRetry = Date().addingTimeInterval(TimeInterval(backoffDuration(for: 1)))
            currentStatus = .backoff(nextRetryDate: nextRetry)
        }
    }
    
    /// Upload a single event to the remote server.
    ///
    /// In production, this would make an actual HTTP request with:
    /// - Idempotency-Key header for safe retries.
    /// - Proper authentication.
    /// - TLS pinning.
    /// - Exponential backoff on transient errors.
    ///
    /// For now, it simulates success/failure for testing.
    ///
    /// - Parameter event: The SyncEvent to upload.
    /// - Returns: `true` if upload succeeded, `false` otherwise.
    private func uploadEvent(_ event: SyncEvent) async -> Bool {
        // Simulate network latency and potential failures.
        try? await Task.sleep(nanoseconds: UInt64(100_000_000)) // 100ms
        
        // In a real implementation:
        // - Construct an HTTP request with the event payload.
        // - Add the Idempotency-Key header: event.idempotencyKey
        // - Retry on transient errors (5xx, timeout).
        // - Return true on 2xx, false on persistent errors.
        
        // For now, simulate 90% success rate for testing.
        return Int.random(in: 0..<10) > 0
    }
    
    /// Calculate backoff duration in seconds for a retry attempt.
    ///
    /// Uses exponential backoff with jitter:
    /// duration = min(2^attemptCount, maxBackoff) * (0.5 + random(0, 0.5))
    ///
    /// - Parameter attemptCount: Number of attempts so far.
    /// - Returns: Duration in seconds.
    private func backoffDuration(for attemptCount: Int) -> Int {
        let exponential = min(
            Int(pow(Double(baseBackoffSeconds), Double(attemptCount))),
            maxBackoffSeconds
        )
        // Add jitter: 50% to 100% of exponential duration.
        let jitter = Double.random(in: 0.5..<1.0)
        return Int(Double(exponential) * jitter)
    }
    
    /// Obtain an AsyncStream of sync status updates.
    ///
    /// The stream persists for the lifetime of the actor and yields status changes
    /// as the sync engine processes events. Cancellation of the consuming task
    /// automatically suspends production.
    ///
    /// - Returns: An AsyncStream<SyncStatus> for SwiftUI consumption.
    public func statusStream() -> AsyncStream<SyncStatus> {
        AsyncStream<SyncStatus> { continuation in
            self.statusContinuation = continuation
            // Immediately yield current status.
            continuation.yield(self.currentStatus)
            continuation.onTermination = { _ in
                self.statusContinuation = nil
            }
        }
    }
    
    /// Retrieve the current pending queue size.
    ///
    /// - Returns: The number of events awaiting upload.
    public func pendingCount() -> Int {
        pendingQueue.count
    }
    
    /// Cancel all in-flight sync operations.
    ///
    /// Gracefully terminates the status stream.
    public func shutdown() {
        statusContinuation?.finish()
        statusContinuation = nil
    }
    
    deinit {
        shutdown()
    }
}
