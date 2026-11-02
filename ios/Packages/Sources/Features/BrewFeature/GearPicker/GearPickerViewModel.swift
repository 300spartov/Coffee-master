import Foundation
import Observation
import AppCore
import Domain
import BrewKit
import DesignSystem
import FactoryKit

/// Picks a bag, dripper, filter pack or grinder for the brew setup. Lists what you own; for devices
/// you don't have yet, offers the catalog's models for this method (tap adds and picks it).
@Observable
final class GearPickerViewModel {
    /// One row in the picker.
    struct Row: Identifiable, Equatable {
        enum Source: Equatable {
            case owned(UUID)
            case catalog(name: String)
        }

        /// Stock of a bag or filter pack.
        struct Stock: Equatable {
            let fraction: Double
            let level: StockLevel

            init(_ item: some Stocked) {
                fraction = item.remainingFraction
                level = StockLevel(item)
            }
        }

        let source: Source
        let title: String
        let subtitle: String?
        let stock: Stock?
        /// For drippers, the drawing to show.
        let dripperKind: DripperKind?

        var id: String {
            switch source {
            case .owned(let id): id.uuidString
            case .catalog(let name): "catalog:\(name)"
            }
        }

        /// The inventory item's ID (`nil` for catalog suggestions).
        var ownedID: UUID? {
            if case .owned(let id) = source { id } else { nil }
        }
    }

    let kind: GearKind
    let method: BrewMethod
    let selectedID: UUID?
    private(set) var state: LoadState = .loading
    private(set) var owned: [Row] = []
    /// Owned items that don't fit the method (filter packs for another brewer), still pickable.
    private(set) var others: [Row] = []
    /// Catalog models, offered when you own none that fit.
    private(set) var suggestions: [Row] = []
    var alertMessage: String?

    @ObservationIgnored private var picks: [UUID: GearPick] = [:]
    @ObservationIgnored private var isAdding = false
    @ObservationIgnored @Injected(\.beanRepository) private var beans
    @ObservationIgnored @Injected(\.deviceRepository) private var devices
    @ObservationIgnored @Injected(\.filterPackRepository) private var filterPacks
    @ObservationIgnored private weak var router: (any GearPickerRouting)?

    init(kind: GearKind, method: BrewMethod, selectedID: UUID?, router: any GearPickerRouting) {
        self.kind = kind
        self.method = method
        self.selectedID = selectedID
        self.router = router
    }

    var title: String { kind.prompt(for: method) }
    var isEmpty: Bool { owned.isEmpty && others.isEmpty && suggestions.isEmpty }

    /// Loads now and again when the inventory changes (e.g. after adding something from here).
    func start() async {
        switch kind {
        case .bean: await beans.observe { await self.load() }
        case .filter: await filterPacks.observe { await self.load() }
        case .dripper, .grinder, .espressoMachine: await devices.observe { await self.load() }
        }
    }

    func load() async {
        do {
            switch kind {
            case .bean: show(try await beans.fetchAll(), row: Row.init(bean:), pick: GearPick.bean)
            case .filter: show(try await filterPacks.fetchAll(), row: Row.init(filterPack:), pick: GearPick.filterPack) { $0.fits(method) }
            case .dripper, .grinder, .espressoMachine: try await loadDevices()
            }
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func isSelected(_ row: Row) -> Bool {
        selectedID != nil && row.ownedID == selectedID
    }

    func didSelect(_ row: Row) async {
        switch row.source {
        case .owned(let id):
            if let pick = picks[id] { router?.gearPickerDidPick(pick) }
        case .catalog(let name):
            await addFromCatalog(name)
        }
    }

    func didTapAdd() {
        router?.gearPickerDidTapAdd(kind)
    }

    // MARK: - Private

    /// Lists `items`: the ones that `fit` first, the rest under `others`.
    private func show<Item: Identifiable>(
        _ items: [Item],
        row: (Item) -> Row,
        pick: (Item) -> GearPick,
        fits: (Item) -> Bool = { _ in true }
    ) where Item.ID == UUID {
        owned = items.filter(fits).map(row)
        others = items.filter { !fits($0) }.map(row)
        picks = Dictionary(uniqueKeysWithValues: items.map { ($0.id, pick($0)) })
        suggestions = []
    }

    private func loadDevices() async throws {
        guard let type = kind.deviceType else { return }
        // Devices that don't fit aren't offered at all (a V60 can't brew an AeroPress recipe).
        let fitting = try await devices.fetchAll(of: type).filter(fits)
        show(fitting, row: { Row(device: $0, kind: kind) }, pick: GearPick.device)
        if fitting.isEmpty {
            suggestions = DeviceCatalog.devices(of: type)
                .filter { fits(name: $0.name) }
                .map { Row(catalog: $0, kind: kind) }
        }
    }

    /// Adds a catalog model to your devices (unless you already have it) and picks it.
    private func addFromCatalog(_ name: String) async {
        guard let type = kind.deviceType, !isAdding else { return }
        isAdding = true
        defer { isAdding = false }
        do {
            let device = try await devices.fetchAll(of: type).first { Device.namesMatch($0.name, name) }
                ?? Device(name: name, type: type)
            try await devices.save(device)
            router?.gearPickerDidPick(.device(device))
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func fits(_ device: Device) -> Bool { fits(name: device.name) }

    private func fits(name: String) -> Bool {
        kind != .dripper || DripperKind(deviceName: name).fits(method)
    }
}

// MARK: - Rows (also used by the setup screen for what's picked)

extension GearPickerViewModel.Row {
    /// "Roaster · 160 / 250 g", with the bag's stock.
    init(bean: Bean) {
        let amounts = "\(decimal(bean.remainingGrams)) / \(decimal(bean.totalGrams)) g"
        self.init(
            source: .owned(bean.id),
            title: bean.name,
            subtitle: bean.roaster.isEmpty ? amounts : "\(bean.roaster) · \(amounts)",
            stock: Stock(bean),
            dripperKind: nil
        )
    }

    /// "Chemex · 64 of 100 left", with the pack's stock.
    init(filterPack pack: FilterPack) {
        self.init(
            source: .owned(pack.id),
            title: pack.name,
            subtitle: [pack.shape?.displayName, tr("\(pack.remaining) of \(pack.total) left")].compactMap { $0 }.joined(separator: " · "),
            stock: Stock(pack),
            dripperKind: nil
        )
    }

    /// Drippers show their kind ("Origami") and drawing.
    init(device: Device, kind: GearKind) {
        let dripperKind = kind == .dripper ? DripperKind(deviceName: device.name) : nil
        self.init(source: .owned(device.id), title: device.name, subtitle: dripperKind?.displayName, stock: nil, dripperKind: dripperKind)
    }

    /// A catalog model you don't own yet (tapping adds it).
    init(catalog device: CatalogDevice, kind: GearKind) {
        let dripperKind = kind == .dripper ? DripperKind(deviceName: device.name) : nil
        self.init(source: .catalog(name: device.name), title: device.name, subtitle: device.details, stock: nil, dripperKind: dripperKind)
    }
}
