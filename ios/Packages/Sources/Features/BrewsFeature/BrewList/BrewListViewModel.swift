import Foundation
import Observation
import AppCore
import Domain
import FactoryKit
@Observable
final class BrewListViewModel {
    private(set) var state: ListState<Brew> = .loading
    /// A failed action (e.g. delete), shown as an alert over the list.
    var alertMessage: String?

    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any BrewListRouting)?

    init(router: any BrewListRouting) {
        self.router = router
    }

    /// Bound to the view's lifetime via `.task`: loads, then reloads on every repository change.
    func start() async {
        await repository.observe { await self.load() }
    }

    func load() async {
        do {
            state = ListState(try await repository.fetchAll())
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
            // Keep the list; the change stream reloads whatever did get deleted.
            alertMessage = error.localizedDescription
        }
    }
}
