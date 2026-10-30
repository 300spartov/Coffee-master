import Foundation
import Observation
import Domain
import FactoryKit

/// The Devices tab root: one tile per category with how many devices you own, plus filter packs.
@Observable
final class DeviceCategoriesViewModel {
    private(set) var ownedCounts: [DeviceType: Int] = [:]
    private(set) var filterPackCount = 0
    /// Packs at or below `FilterPack.lowStockThreshold` (including empty ones).
    private(set) var lowFilterPackCount = 0

    @ObservationIgnored @Injected(\.deviceRepository) private var repository
    @ObservationIgnored @Injected(\.filterPackRepository) private var filterPacks
    @ObservationIgnored private weak var router: (any DeviceCategoriesRouting)?

    init(router: any DeviceCategoriesRouting) {
        self.router = router
    }

    var categories: [DeviceType] { DeviceType.browsable }

    /// Bound to the view's lifetime via `.task`: loads, then reloads when devices or filter packs change.
    func start() async {
        let deviceChanges = await repository.changes()
        let packChanges = await filterPacks.changes()
        await load()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { for await _ in deviceChanges { await self.load() } }
            group.addTask { for await _ in packChanges { await self.load() } }
        }
    }

    func load() async {
        // Counts are a hint on the tiles; if they can't load, the screens are still usable.
        let devices = (try? await repository.fetchAll()) ?? []
        ownedCounts = Dictionary(grouping: devices, by: \.type).mapValues(\.count)
        let packs = (try? await filterPacks.fetchAll()) ?? []
        filterPackCount = packs.count
        lowFilterPackCount = packs.filter(\.isLow).count
    }

    func ownedCount(_ type: DeviceType) -> Int { ownedCounts[type] ?? 0 }

    func catalogCount(_ type: DeviceType) -> Int { DeviceCatalog.devices(of: type).count }

    func didSelect(_ type: DeviceType) {
        router?.showCategory(type)
    }

    func didSelectFilters() {
        router?.showFilterPacks()
    }
}
