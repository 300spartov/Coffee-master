import Foundation
import Domain

public struct CoreDataBeanRepository: BeanRepository {
    private let store: RecordStore<Bean>

    public init(persistence: PersistenceController) {
        store = RecordStore(persistence: persistence)
    }

    public func fetchAll() async throws -> [Bean] { try await store.fetchAll() }

    public func fetch(id: Bean.ID) async throws -> Bean {
        guard let bean = try await store.fetch(id: id) else { throw RepositoryError.notFound }
        return bean
    }

    public func save(_ bean: Bean) async throws {
        var bean = bean
        bean.touch()
        try await store.upsert([bean], policy: .overwrite)
    }

    public func delete(id: Bean.ID) async throws { try await store.softDelete(id: id) }

    @discardableResult
    public func consume(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try await store.mutate(id: beanID) { $0.consume(grams: grams) }
    }

    @discardableResult
    public func restock(beanID: Bean.ID, grams: Double) async throws -> Bean {
        try await store.mutate(id: beanID) { $0.restock(grams: grams) }
    }

    public func changes() async -> AsyncStream<Void> { store.changes() }
}
