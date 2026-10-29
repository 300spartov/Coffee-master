import Foundation
import Domain
@testable import BrewsFeature

struct TestError: LocalizedError {
    var errorDescription: String? { "Boom" }
}

actor MockBrewRepository: BrewRepository {
    private(set) var brews: [Brew]
    private(set) var savedBrews: [Brew] = []
    private let error: (any Error)?
    /// Fails only `delete` (reads keep working).
    private let deleteError: (any Error)?

    init(brews: [Brew] = [], error: (any Error)? = nil, deleteError: (any Error)? = nil) {
        self.brews = brews
        self.error = error
        self.deleteError = deleteError
    }

    func fetchAll() throws -> [Brew] {
        if let error { throw error }
        return brews
    }

    func fetch(id: Brew.ID) throws -> Brew {
        if let error { throw error }
        guard let brew = brews.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return brew
    }

    func save(_ brew: Brew) throws {
        if let error { throw error }
        savedBrews.append(brew)
        brews.append(brew)
    }

    func delete(id: Brew.ID) throws {
        if let error = error ?? deleteError { throw error }
        brews.removeAll { $0.id == id }
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { _ in }
    }
}

@MainActor
final class SpyRouter: BrewListRouting, BrewDetailRouting, NewBrewRouting {
    private(set) var shownDetailIDs: [Brew.ID] = []
    private(set) var newBrewShownCount = 0
    private(set) var deletedIDs: [Brew.ID] = []
    private(set) var notFoundIDs: [Brew.ID] = []
    private(set) var finishedNewBrews: [Brew?] = []

    func showBrewDetail(id: Brew.ID) { shownDetailIDs.append(id) }
    func showNewBrew() { newBrewShownCount += 1 }
    func brewDetailDidDelete(id: Brew.ID) { deletedIDs.append(id) }
    func brewDetailNotFound(id: Brew.ID) { notFoundIDs.append(id) }
    func newBrewDidFinish(saved brew: Brew?) { finishedNewBrews.append(brew) }
}
