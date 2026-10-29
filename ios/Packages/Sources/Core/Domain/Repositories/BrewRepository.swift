import Foundation

/// CRUD shared by every syncable record type. Features depend on the specific protocols below;
/// concrete implementations live in `DataLayer` (Core Data) and `Fixtures` (in-memory, for previews/tests).
public protocol RecordRepository<Record>: Sendable {
    associatedtype Record: Syncable

    /// Active records (not in the trash), in the type's natural order.
    func fetchAll() async throws -> [Record]
    /// Throws `RepositoryError.notFound` if missing or trashed.
    func fetch(id: Record.ID) async throws -> Record
    /// Inserts or updates, stamping `updatedAt` so the edit wins in sync.
    func save(_ record: Record) async throws
    /// Soft delete (`deletedAt`), so the deletion can sync to other devices.
    func delete(id: Record.ID) async throws
    /// Emits after every write. The stream finishes when the consuming task is cancelled.
    func changes() async -> AsyncStream<Void>
}

/// Brews, newest first. `delete` moves a brew to the trash and returns its coffee and filter
/// to stock (like the web app); see `TrashRepository` to restore or purge.
public protocol BrewRepository: RecordRepository where Record == Brew {}

public enum RepositoryError: Error, Equatable {
    case notFound
}
