import Foundation
import Observation
import Domain
import FactoryKit

/// Paper filter packs with how many are left; −/+ correct the count by hand
/// (brews will use filters automatically once the brew flow saves them, ROADMAP 2.7).
@Observable
final class FilterPacksViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([FilterPack])
        case failed(String)
    }

    private(set) var state: State = .loading
    var alertMessage: String?

    @ObservationIgnored @Injected(\.filterPackRepository) private var repository
    @ObservationIgnored private weak var router: (any FilterPacksRouting)?

    init(router: any FilterPacksRouting) {
        self.router = router
    }

    func start() async {
        let changes = await repository.changes()
        await load()
        for await _ in changes {
            await load()
        }
    }

    func load() async {
        do {
            let packs = try await repository.fetchAll()
            state = packs.isEmpty ? .empty : .loaded(packs)
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
