import Foundation

/// A user-owned record that is stored locally and synced per record with the backend.
///
/// Sync rules (see ROADMAP D3): last write wins on `updatedAt`; deletes are soft (`deletedAt`)
/// so they can propagate to other devices and power the trash.
public protocol Syncable: Identifiable, Hashable, Codable, Sendable where ID == UUID {
    var id: UUID { get }
    /// Numeric id from the web app, set only for records imported from its JSON export.
    var legacyID: Int? { get }
    var updatedAt: Date { get set }
    var deletedAt: Date? { get set }
}

public extension Syncable {
    var isDeleted: Bool { deletedAt != nil }

    mutating func touch(at date: Date = .now) {
        updatedAt = date
    }

    mutating func markDeleted(at date: Date = .now) {
        deletedAt = date
        updatedAt = date
    }

    mutating func restore(at date: Date = .now) {
        deletedAt = nil
        updatedAt = date
    }
}
