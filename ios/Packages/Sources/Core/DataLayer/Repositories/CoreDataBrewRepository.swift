import Foundation
import Domain

/// Core Data–backed `BrewRepository`. Deleting moves a brew to the trash (soft delete).
public struct CoreDataBrewRepository: BrewRepository {
    private let store: RecordStore<Brew>

    public init(persistence: PersistenceController) {
        store = RecordStore(persistence: persistence)
    }

    /// Active brews, newest first.
    public func fetchAll() async throws -> [Brew] {
        try await store.fetchAll()
    }

    public func fetch(id: Brew.ID) async throws -> Brew {
        guard let brew = try await store.fetch(id: id) else { throw RepositoryError.notFound }
        return brew
    }

    /// Inserts or updates; stamps `updatedAt` so the edit wins in sync.
    public func save(_ brew: Brew) async throws {
        var brew = brew
        brew.touch()
        try await store.upsert([brew], policy: .overwrite)
    }

    public func delete(id: Brew.ID) async throws {
        try await store.softDelete(id: id)
    }

    public func changes() async -> AsyncStream<Void> {
        store.changes()
    }
}
