import Foundation
import FactoryKit

/// A brew being set up: the picked gear (full items, for showing their stock) and the recipe.
/// The wizard edits it; `setup` is what gets brewed. `init(method:history:…)` prefills it.
public struct BrewSetupDraft: Equatable, Sendable {
    public var bean: Bean?
    public var dripper: Device?
    public var filter: FilterPack?
    public var grinder: Device?
    /// Dose, ratio, grind, temperature, pours, rinse, AeroPress options. Its gear references are
    /// filled in from the items above by `setup`.
    public var recipe: BrewSetup

    /// Nothing picked, default recipe.
    public init(method: BrewMethod) {
        recipe = BrewSetup(method: method)
    }

    /// Prefilled: the recipe of the last brew with this method, and gear from the inventory.
    ///
    /// Rules:
    /// - **Bag**: the last one used for this kind of brew if it still has coffee and fits; otherwise
    ///   the only bag that fits (filter roast for filter methods, espresso roast for espresso, Omni and
    ///   Auto for both); otherwise the only bag there is.
    /// - **Brewer**: the last one used with this method if you still have it; otherwise one you own
    ///   that fits the method (an AeroPress for AeroPress).
    /// - **Filter pack**: of the packs that fit the method (`FilterPack.fits`), the last one used if it
    ///   has filters left; otherwise the only one with filters.
    /// - **Grinder**: the last one used; otherwise the one you own.
    ///
    /// `history`: newest first (`BrewSetupHistory.recentSetups()`).
    public init(
        method: BrewMethod,
        history: [BrewSetup],
        beans: [Bean],
        drippers: [Device],
        filters: [FilterPack],
        grinders: [Device]
    ) {
        let sameMethod = history.first { $0.method == method }
        let sameKind = history.filter { $0.method.isEspressoBased == method.isEspressoBased }
        var recipe = sameMethod ?? BrewSetup(method: method)
        recipe.bean = nil
        recipe.dripper = nil
        recipe.filter = nil
        recipe.grinder = nil
        self.recipe = recipe

        bean = Self.bag(from: beans, lastID: sameKind.lazy.compactMap { $0.bean?.beanID }.first, espresso: method.isEspressoBased)

        // Brewer
        if recipe.usesDripper {
            let fittingDrippers = drippers.filter { DripperKind(deviceName: $0.name).fits(method) }
            dripper = fittingDrippers.first { $0.id == sameMethod?.dripper?.id } ?? fittingDrippers.first
        }

        // Filter pack
        if recipe.usesFilter {
            let withFilters = filters.filter { !$0.isEmpty && $0.fits(method) }
            let lastFilterID = sameKind.lazy.compactMap { $0.filter?.id }.first
            filter = withFilters.first { $0.id == lastFilterID } ?? (withFilters.count == 1 ? withFilters.first : nil)
        }

        // Grinder
        let lastGrinderID = history.lazy.compactMap { $0.grinder?.id }.first
        grinder = grinders.first { $0.id == lastGrinderID } ?? grinders.first
    }
}

public extension BrewSetupDraft {
    /// The recipe within its limits, with the picked gear: ready to brew.
    var setup: BrewSetup {
        var setup = recipe.validated()
        setup.bean = bean.map(BeanReference.init)
        setup.dripper = dripper.map(GearReference.init)
        setup.filter = filter.map(GearReference.init)
        setup.grinder = grinder.map(GearReference.init)
        return setup
    }

    /// `other` with the gear picked here kept (prefill doesn't undo the user's picks).
    func keepingPicks(over other: BrewSetupDraft) -> BrewSetupDraft {
        var merged = other
        merged.bean = bean ?? other.bean
        merged.dripper = dripper ?? other.dripper
        merged.filter = filter ?? other.filter
        merged.grinder = grinder ?? other.grinder
        return merged
    }
}

extension BrewSetupDraft {
    /// The bag rule, shared with espresso: the last one used if it still has coffee and fits; otherwise
    /// the only bag that fits the roast; otherwise the only bag there is.
    static func bag(from beans: [Bean], lastID: UUID?, espresso: Bool) -> Bean? {
        let withCoffee = beans.filter { !$0.isEmpty }
        let fitting = withCoffee.filter { $0.roastProfile.fits(espresso: espresso) }
        return fitting.first { $0.id == lastID }
            ?? (fitting.count == 1 ? fitting.first : nil)
            ?? (withCoffee.count == 1 ? withCoffee.first : nil)
    }
}

private extension Optional where Wrapped == RoastProfile {
    /// Auto (`nil`) and Omni suit any brew.
    func fits(espresso: Bool) -> Bool {
        switch self {
        case nil, .omni: true
        case .filter: !espresso
        case .espresso: espresso
        }
    }
}

// MARK: - Loading

public extension BrewSetupDraft {
    /// Prefills (`init(method:history:…)`) to the current inventory and history (from DI). A list that can't be read
    /// counts as empty: prefilling is a convenience, never a reason to block the brew.
    static func prefilled(for method: BrewMethod) async -> BrewSetupDraft {
        let container = Container.shared
        let devices = (try? await container.deviceRepository().fetchAll()) ?? []
        return BrewSetupDraft(
            method: method,
            history: await container.brewSetupHistory().recentSetups(),
            beans: (try? await container.beanRepository().fetchAll()) ?? [],
            drippers: devices.filter { $0.type == .dripper },
            filters: (try? await container.filterPackRepository().fetchAll()) ?? [],
            grinders: devices.filter { $0.type == .grinder }
        )
    }
}

public extension BeanReference {
    /// A snapshot of `bean`, linked to it.
    init(_ bean: Bean) {
        self.init(beanID: bean.id, name: bean.name, roaster: bean.roaster, roastProfile: bean.roastProfile)
    }
}

public extension GearReference {
    init(_ device: Device) {
        self.init(id: device.id, name: device.name)
    }

    init(_ pack: FilterPack) {
        self.init(id: pack.id, name: pack.name)
    }
}
