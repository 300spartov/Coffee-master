import Foundation
import Domain

public struct CoreDataTrashRepository: TrashRepository {
    private let store: RecordStore<Brew>

    public init(persistence: PersistenceController) {
        store = RecordStore(persistence: persistence)
    }

    public func trashedBrews() async throws -> [Brew] {
        try await store.fetchAll(deleted: .only)
            .sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    public func restore(brewID: Brew.ID) async throws {
        try await store.persistence.write { context in
            var wasTrashed = false
            let restored = try RecordStore<Brew>.mutate(id: brewID, includeDeleted: true, in: context) { brew in
                wasTrashed = brew.isDeleted
                if wasTrashed { brew.restore() }
            }
            guard wasTrashed else { throw RepositoryError.notFound }
            try BrewStockEffects.apply(.takeFromStock, for: restored, in: context)
        }
    }

    public func deletePermanently(brewID: Brew.ID) async throws {
        try await store.deletePermanently(id: brewID)
    }

    public func emptyTrash() async throws {
        try await store.purgeDeleted(before: .distantFuture)
    }

    @discardableResult
    public func purgeExpired(now: Date) async throws -> Int {
        try await store.purgeDeleted(before: TrashPolicy.expiryDate(now: now))
    }

    public func changes() async -> AsyncStream<Void> {
        store.changes()
    }
}
