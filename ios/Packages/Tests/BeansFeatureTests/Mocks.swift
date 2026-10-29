import Foundation
import Domain
@testable import BeansFeature

struct TestError: LocalizedError {
    var errorDescription: String? { "Boom" }
}

actor MockBeanRepository: BeanRepository {
    private(set) var beans: [Bean]
    private(set) var savedBeans: [Bean] = []
    private let error: (any Error)?
    /// Fails only `delete` (reads keep working).
    private let deleteError: (any Error)?

    init(beans: [Bean] = [], error: (any Error)? = nil, deleteError: (any Error)? = nil) {
        self.beans = beans
        self.error = error
        self.deleteError = deleteError
    }

    func fetchAll() throws -> [Bean] {
        if let error { throw error }
        return beans
    }

    func fetch(id: Bean.ID) throws -> Bean {
        if let error { throw error }
        guard let bean = beans.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return bean
    }

    func save(_ bean: Bean) throws {
        if let error { throw error }
        savedBeans.append(bean)
        beans.append(bean)
    }

    func delete(id: Bean.ID) throws {
        if let error = error ?? deleteError { throw error }
        beans.removeAll { $0.id == id }
    }

    func consume(beanID: Bean.ID, grams: Double) throws -> Bean {
        if let error { throw error }
        guard let index = beans.firstIndex(where: { $0.id == beanID }) else { throw RepositoryError.notFound }
        beans[index].consume(grams: grams)
        return beans[index]
    }

    func restock(beanID: Bean.ID, grams: Double) throws -> Bean {
        if let error { throw error }
        guard let index = beans.firstIndex(where: { $0.id == beanID }) else { throw RepositoryError.notFound }
        beans[index].restock(grams: grams)
        return beans[index]
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { _ in }
    }
}

@MainActor
final class SpyRouter: BeanListRouting {
    private(set) var shownDetailIDs: [Bean.ID] = []
    private(set) var addBeanShownCount = 0

    func showBeanDetail(id: Bean.ID) { shownDetailIDs.append(id) }
    func showAddBean() { addBeanShownCount += 1 }
}
