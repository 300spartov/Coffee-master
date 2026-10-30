import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

@Observable
final class BeanListViewModel {
    private(set) var state: ListState<Bean> = .loading
    /// A failed action (e.g. delete), shown as an alert over the list.
    var alertMessage: String?

    @ObservationIgnored @Injected(\.beanRepository) private var repository
    @ObservationIgnored private weak var router: (any BeanListRouting)?

    init(router: any BeanListRouting) {
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

    func didSelect(_ bean: Bean) {
        router?.showBeanDetail(id: bean.id)
    }

    func didTapAdd() {
        router?.showAddBean()
    }

    func delete(_ beans: [Bean]) async {
        do {
            for bean in beans {
                try await repository.delete(id: bean.id)
            }
        } catch {
            // Keep the list; the change stream reloads whatever did get deleted.
            alertMessage = error.localizedDescription
        }
    }
}
