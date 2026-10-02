import CoreDomain
import Foundation
import SwiftData

/// Concrete implementations wrap SwiftData/SQLCipher. This protocol boundary keeps
/// the domain and sync engine independent of a particular encrypted store.
public protocol PersistenceClient: EventStore {}

/// A minimal SwiftData projection seed. Production projections remain derived
/// from the encrypted append-only log rather than becoming a second authority.
@Model
public final class PersistedIncident {
    @Attribute(.unique) public var id: UUID
    public var updatedAt: Date

    public init(id: UUID, updatedAt: Date = .now) {
        self.id = id
        self.updatedAt = updatedAt
    }
}
