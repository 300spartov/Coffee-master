import Foundation
import Observation
import Domain
import FactoryKit
@Observable
final class BrewDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(Brew)
        case failed(String)
    }

    private(set) var state: State = .loading
    var alertMessage: String?

    @ObservationIgnored private let brewID: Brew.ID
    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any BrewDetailRouting)?

    init(brewID: Brew.ID, router: any BrewDetailRouting) {
        self.brewID = brewID
        self.router = router
    }

    func load() async {
        do {
            state = .loaded(try await repository.fetch(id: brewID))
        } catch RepositoryError.notFound {
            router?.brewDetailNotFound(id: brewID)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func delete() async {
        do {
            try await repository.delete(id: brewID)
            router?.brewDetailDidDelete(id: brewID)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
