import Foundation
import Observation
import Domain

/// Wizard step 1: Alternative or Espresso (`group == nil`), then step 2: a method from that group.
@Observable
final class MethodPickViewModel {
    let group: MethodGroup?

    @ObservationIgnored private weak var router: (any MethodPickRouting)?

    init(group: MethodGroup? = nil, router: any MethodPickRouting) {
        self.group = group
        self.router = router
    }

    var groups: [MethodGroup] { MethodGroup.allCases }

    var methods: [BrewMethod] { group?.methods ?? [] }

    func didSelect(group: MethodGroup) {
        router?.showMethods(in: group)
    }

    func didSelect(method: BrewMethod) {
        router?.methodPickDidSelect(method)
    }

    func cancel() {
        router?.methodPickDidCancel()
    }
}
