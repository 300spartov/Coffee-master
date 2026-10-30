import Foundation
import Observation
import Domain
import FactoryKit

/// The Devices tab root: one tile per category with how many devices you own.
@Observable
final class DeviceCategoriesViewModel {
    private(set) var ownedCounts: [DeviceType: Int] = [:]

    @ObservationIgnored @Injected(\.deviceRepository) private var repository
    @ObservationIgnored private weak var router: (any DeviceCategoriesRouting)?

    init(router: any DeviceCategoriesRouting) {
        self.router = router
    }

    var categories: [DeviceType] { DeviceType.browsable }

    /// Bound to the view's lifetime via `.task`: loads, then reloads on every repository change.
    func start() async {
        let changes = await repository.changes()
        await load()
        for await _ in changes {
            await load()
        }
    }

    func load() async {
        // Counts are a hint on the tiles; if they can't load, the catalog is still usable.
        let devices = (try? await repository.fetchAll()) ?? []
        ownedCounts = Dictionary(grouping: devices, by: \.type).mapValues(\.count)
    }

    func ownedCount(_ type: DeviceType) -> Int { ownedCounts[type] ?? 0 }

    func catalogCount(_ type: DeviceType) -> Int { DeviceCatalog.devices(of: type).count }

    func didSelect(_ type: DeviceType) {
        router?.showCategory(type)
    }
}
