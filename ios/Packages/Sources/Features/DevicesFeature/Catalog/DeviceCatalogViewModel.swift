import Foundation
import Observation
import Domain
import FactoryKit

/// One category: the devices you own, the built-in catalog with add/remove toggles, search,
/// and quick-add for something the catalog doesn't have.
@Observable
final class DeviceCatalogViewModel {
    let type: DeviceType
    /// Search text (from the navigation bar's search field).
    var query = ""
    private(set) var owned: [Device] = []
    var alertMessage: String?

    @ObservationIgnored private let catalog: [CatalogDevice]
    /// Names with an add/remove in flight, so a fast double tap doesn't run twice.
    @ObservationIgnored private var pendingNames: Set<String> = []
    @ObservationIgnored @Injected(\.deviceRepository) private var repository
    @ObservationIgnored private weak var router: (any DeviceCatalogRouting)?

    init(type: DeviceType, router: any DeviceCatalogRouting) {
        self.type = type
        self.router = router
        catalog = DeviceCatalog.devices(of: type)
    }

    // MARK: - Derived

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isSearching: Bool { !trimmedQuery.isEmpty }

    var visibleOwned: [Device] {
        isSearching ? owned.filter { matches($0.name) } : owned
    }

    var visibleCatalog: [CatalogDevice] {
        isSearching ? catalog.filter { matches($0.name) || matches($0.details) } : catalog
    }

    var catalogCount: Int { catalog.count }

    func isOwned(_ item: CatalogDevice) -> Bool {
        ownedDevice(named: item.name) != nil
    }

    /// The typed text, when neither the catalog nor your devices have exactly that name.
    var quickAddName: String? {
        let name = trimmedQuery
        guard !name.isEmpty,
              !catalog.contains(where: { Device.namesMatch($0.name, name) }),
              ownedDevice(named: name) == nil
        else { return nil }
        return name
    }

    // MARK: - Loading

    func start() async {
        let changes = await repository.changes()
        await load()
        for await _ in changes {
            await load()
        }
    }

    func load() async {
        do {
            owned = try await repository.fetchAll(of: type)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    // MARK: - Actions

    /// Adds a catalog device to your inventory, or removes it (and any duplicates) if you have it.
    /// Decides from the repository, not the possibly stale `owned` list.
    func toggle(_ item: CatalogDevice) async {
        await whileNotPending(item.name) {
            let matching = try await self.repository.fetchAll(of: self.type).filter { Device.namesMatch($0.name, item.name) }
            if matching.isEmpty {
                try await self.repository.save(Device(name: item.name, type: self.type))
            } else {
                for device in matching {
                    try await self.repository.delete(id: device.id)
                }
            }
        }
    }

    func quickAdd() async {
        guard let name = quickAddName else { return }
        await whileNotPending(name) {
            guard try await !self.repository.contains(name: name, type: self.type) else { return }
            try await self.repository.save(Device(name: name, type: self.type))
        }
    }

    func delete(_ devices: [Device]) async {
        do {
            for device in devices {
                try await repository.delete(id: device.id)
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func didSelect(_ device: Device) {
        router?.showEditDevice(id: device.id)
    }

    func didTapAdd() {
        router?.showAddDevice(type: type)
    }

    // MARK: - Private

    /// Runs `work` unless the same name is already being added/removed; reloads afterwards so the
    /// screen reflects the result even before the change notification arrives.
    private func whileNotPending(_ name: String, _ work: @escaping () async throws -> Void) async {
        let key = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        guard pendingNames.insert(key).inserted else { return }
        defer { pendingNames.remove(key) }
        do {
            try await work()
        } catch {
            alertMessage = error.localizedDescription
        }
        await load()
    }

    private func ownedDevice(named name: String) -> Device? {
        owned.first { Device.namesMatch($0.name, name) }
    }

    private func matches(_ text: String) -> Bool {
        text.range(of: trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
