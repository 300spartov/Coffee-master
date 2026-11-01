import Foundation
import FactoryKit

/// An espresso being set up: the picked gear (full items) and the recipe; `setup` is what's pulled.
public struct EspressoDraft: Equatable, Sendable {
    public var bean: Bean?
    public var machine: Device?
    public var grinder: Device?
    public var accessories: [Device] = []
    /// Dose, ratio, grind, temperature, pressure. Gear references are filled in by `setup`.
    public var recipe: EspressoSetup

    /// Nothing picked, default recipe.
    public init(method: BrewMethod) {
        recipe = EspressoSetup(method: method)
    }

    /// Prefilled like a pour-over (`BrewSetupDraft`): the recipe of the last shot of this drink (or of
    /// any espresso), the bag that fits an espresso, and the machine, grinder and accessories used last
    /// (or the ones you own).
    public init(
        method: BrewMethod,
        history: [EspressoSetup],
        pourOverHistory: [BrewSetup],
        beans: [Bean],
        devices: [Device]
    ) {
        let last = history.first { $0.method == method } ?? history.first
        var recipe = last ?? EspressoSetup(method: method)
        recipe.method = method
        recipe.bean = nil
        recipe.machine = nil
        recipe.grinder = nil
        recipe.accessories = []
        self.recipe = recipe

        bean = BrewSetupDraft.bag(from: beans, lastID: history.lazy.compactMap { $0.bean?.beanID }.first, espresso: true)
        let machines = devices.filter { $0.type == .espressoMachine }
        machine = machines.first { $0.id == last?.machine?.id } ?? machines.first
        let grinders = devices.filter { $0.type == .grinder }
        let lastGrinderID = (history.lazy.compactMap { $0.grinder?.id } + pourOverHistory.lazy.compactMap { $0.grinder?.id }).first
        grinder = grinders.first { $0.id == lastGrinderID } ?? grinders.first
        let lastAccessories = Set(last?.accessories.compactMap(\.id) ?? [])
        accessories = devices.filter { $0.type == .accessory && lastAccessories.contains($0.id) }
    }

    /// The recipe within its limits, with the picked gear.
    public var setup: EspressoSetup {
        var setup = recipe.validated()
        setup.bean = bean.map(BeanReference.init)
        setup.machine = machine.map(GearReference.init)
        setup.grinder = grinder.map(GearReference.init)
        setup.accessories = accessories.map(GearReference.init)
        return setup
    }

    /// `other` with the gear picked here kept.
    public func keepingPicks(over other: EspressoDraft) -> EspressoDraft {
        var merged = other
        merged.bean = bean ?? other.bean
        merged.machine = machine ?? other.machine
        merged.grinder = grinder ?? other.grinder
        if !accessories.isEmpty { merged.accessories = accessories }
        return merged
    }

    /// Prefills from the current inventory and history (from DI); unreadable lists count as empty.
    public static func prefilled(for method: BrewMethod) async -> EspressoDraft {
        let container = Container.shared
        let history = container.brewSetupHistory()
        return EspressoDraft(
            method: method,
            history: await history.recentEspressoSetups(),
            pourOverHistory: await history.recentSetups(),
            beans: (try? await container.beanRepository().fetchAll()) ?? [],
            devices: (try? await container.deviceRepository().fetchAll()) ?? []
        )
    }
}
