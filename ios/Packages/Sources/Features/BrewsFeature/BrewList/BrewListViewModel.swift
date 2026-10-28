import Foundation
import Observation
import Domain
import Factory

@MainActor
@Observable
final class BrewListViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([Brew])
        case failed(String)
    }

    private(set) var state: State = .loading

    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any BrewListRouting)?

    init(router: any BrewListRouting) {
        self.router = router
    }

    /// Bound to the view's lifetime via `.task`: loads, then reloads on every repository change.
    func start() async {
        let changes = await repository.changes()
        await load()
        for await _ in changes {
            await load()
        }
    }

    func load() async {
        do {
            let brews = try await repository.fetchAll()
            state = brews.isEmpty ? .empty : .loaded(brews)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func didSelect(_ brew: Brew) {
        router?.showBrewDetail(id: brew.id)
    }

    func didTapAdd() {
        router?.showNewBrew()
    }

    func delete(_ brews: [Brew]) async {
        do {
            for brew in brews {
                try await repository.delete(id: brew.id)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
