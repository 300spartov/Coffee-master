import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Paper filter packs with how many are left; −/+ correct the count by hand
/// (brews will use filters automatically once the brew flow saves them, ROADMAP 2.7).
@Observable
final class FilterPacksViewModel {
    private(set) var state: ListState<FilterPack> = .loading
    var alertMessage: String?

    @ObservationIgnored @Injected(\.filterPackRepository) private var repository
    @ObservationIgnored private weak var router: (any FilterPacksRouting)?

    init(router: any FilterPacksRouting) {
        self.router = router
    }

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

    /// One filter used (count goes down, never below zero).
    func useOne(_ pack: FilterPack) async {
        await perform { try await self.repository.use(packID: pack.id, count: 1) }
    }

    /// One filter put back (count goes up, never above the pack size).
    func putBackOne(_ pack: FilterPack) async {
        await perform { try await self.repository.putBack(packID: pack.id, count: 1) }
    }

    func delete(_ packs: [FilterPack]) async {
        await perform {
            for pack in packs {
                try await self.repository.delete(id: pack.id)
            }
        }
    }

    func didSelect(_ pack: FilterPack) {
        router?.showEditFilterPack(id: pack.id)
    }

    func didTapAdd() {
        router?.showAddFilterPack()
    }

    /// Runs a write, keeps the list on failure (alert instead), and reloads so the count updates
    /// right away rather than waiting for the change notification.
    private func perform(_ work: @escaping () async throws -> Void) async {
        do {
            try await work()
        } catch {
            alertMessage = error.localizedDescription
        }
        await load()
    }
}
