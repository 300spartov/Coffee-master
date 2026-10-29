import Foundation
import Domain

public struct CoreDataFilterPackRepository: FilterPackRepository {
    private let store: RecordStore<FilterPack>

    public init(persistence: PersistenceController) {
        store = RecordStore(persistence: persistence)
    }

    public func fetchAll() async throws -> [FilterPack] { try await store.fetchAll() }

    public func fetch(id: FilterPack.ID) async throws -> FilterPack {
        guard let pack = try await store.fetch(id: id) else { throw RepositoryError.notFound }
        return pack
    }

    public func save(_ pack: FilterPack) async throws {
        var pack = pack
        pack.touch()
        try await store.upsert([pack], policy: .overwrite)
    }

    public func delete(id: FilterPack.ID) async throws { try await store.softDelete(id: id) }

    @discardableResult
    public func use(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try await store.mutate(id: packID) { $0.use(count: count) }
    }

    @discardableResult
    public func putBack(packID: FilterPack.ID, count: Int) async throws -> FilterPack {
        try await store.mutate(id: packID) { $0.putBack(count: count) }
    }

    public func changes() async -> AsyncStream<Void> { store.changes() }
}
