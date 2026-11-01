import Foundation
import Observation
import Domain
import FactoryKit

/// One espresso from setup to saved shot, shared by its four screens (setup → shot → milk / ice →
/// result), like the web app's single brew state. The shot clock keeps timestamps.
@Observable
final class EspressoViewModel: GearPickingModel {
    let method: BrewMethod
    var draft: EspressoDraft
    /// Owned accessories, for the accessory chips and the milk frother.
    private(set) var ownedAccessories: [Device] = []
    private(set) var milkSuggestions: [String] = []
    private(set) var mixerSuggestions: [String] = []

    // Shot
    private(set) var shotStartedAt: Date? { didSet { persist() } }
    private(set) var shotStoppedAt: Date? { didSet { persist() } }
    /// The step on screen after the setup (nil on the setup); from then on the brew is kept.
    private(set) var step: EspressoStep? { didSet { persist() } }
    private(set) var now: Date

    // Milk / ice (web defaults)
    var milk = MilkInfo(name: "", temperature: 60, volumeMilliliters: 150, frother: "") { didSet { persist() } }
    var ice = IceInfo(cubes: 4, mixer: "") { didSet { persist() } }

    // Result
    /// Seconds, editable (the timer's value).
    var shotTime: Double = 0 { didSet { persist() } }
    var actualYield: Double? { didSet { persist() } }
    var targetTDS: Double? = 9 { didSet { persist() } }
    var actualTDS: Double? { didSet { persist() } }
    var tasting = BrewTasting() { didSet { persist() } }
    private(set) var isSaving = false
    var alertMessage: String?

    @ObservationIgnored private var didPrefill = false
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored @Injected(\.brewRepository) private var brews
    @ObservationIgnored @Injected(\.deviceRepository) private var devices
    @ObservationIgnored @Injected(\.suggestionsRepository) private var suggestions
    @ObservationIgnored @Injected(\.brewSetupHistory) private var history
    @ObservationIgnored private weak var router: (any EspressoRouting)?

    init(method: BrewMethod, router: any EspressoRouting, clock: @escaping () -> Date = Date.init) {
        self.method = method
        self.router = router
        self.clock = clock
        draft = EspressoDraft(method: method)
        now = clock()
    }

    /// A brew in progress restored after an app kill (prefill is skipped: the gear was already picked).
    convenience init(progress: EspressoProgress, router: any EspressoRouting, clock: @escaping () -> Date = Date.init) {
        self.init(method: progress.draft.recipe.method, router: router, clock: clock)
        didPrefill = true
        draft = progress.draft
        shotStartedAt = progress.shotStartedAt
        shotStoppedAt = progress.shotStoppedAt
        milk = progress.milk
        ice = progress.ice
        shotTime = progress.shotTime
        actualYield = progress.actualYield
        targetTDS = progress.targetTDS
        actualTDS = progress.actualTDS
        tasting = progress.tasting
        step = progress.step
    }

    /// Shows `step` (the flow pushes its screen) and keeps the brew from then on.
    private func advance(to step: EspressoStep) {
        self.step = step
        if let router { router.espresso(EspressoBrew(viewModel: self), didAdvanceTo: step) }
    }

    private func persist() {
        guard let step else { return }
        BrewInProgress.save(.espresso(EspressoProgress(
            step: step,
            draft: draft,
            shotStartedAt: shotStartedAt,
            shotStoppedAt: shotStoppedAt,
            milk: milk,
            ice: ice,
            shotTime: shotTime,
            actualYield: actualYield,
            targetTDS: targetTDS,
            actualTDS: actualTDS,
            tasting: tasting
        )))
    }

    // MARK: - Setup

    /// Prefills once (gear the user already picked is kept) and loads accessories and suggestions.
    func prefill() async {
        guard !didPrefill else { return }
        didPrefill = true
        draft = draft.keepingPicks(over: await EspressoDraft.prefilled(for: method))
        ownedAccessories = ((try? await devices.fetchAll(of: .accessory)) ?? [])
        let remembered = (try? await suggestions.suggestions()) ?? Suggestions()
        milkSuggestions = remembered.milks
        mixerSuggestions = remembered.mixers
    }

    func picked(_ kind: GearKind) -> GearPickerViewModel.Row? {
        switch kind {
        case .bean: draft.bean.map(GearPickerViewModel.Row.init(bean:))
        case .espressoMachine: draft.machine.map { .init(device: $0, kind: .espressoMachine) }
        case .grinder: draft.grinder.map { .init(device: $0, kind: .grinder) }
        case .dripper, .filter: nil
        }
    }

    var gearPresenter: (any GearPickerPresenting)? { router }

    func apply(_ pick: GearPick) {
        switch pick {
        case .bean(let bean): draft.bean = bean
        case .device(let device) where device.type == .grinder: draft.grinder = device
        case .device(let device) where device.type == .espressoMachine: draft.machine = device
        case .device, .filterPack: break
        }
    }

    /// Accessory chips, by ID.
    var accessorySelection: Set<UUID> {
        get { Set(draft.accessories.map(\.id)) }
        set { draft.accessories = ownedAccessories.filter { newValue.contains($0.id) } }
    }

    /// Remembers the recipe for next time and goes to the shot.
    func startShotStep() async {
        await history.remember(draft.setup)
        advance(to: .shot)
    }

    // MARK: - Shot

    var isShotRunning: Bool { shotStartedAt != nil && shotStoppedAt == nil }

    var shotElapsed: TimeInterval {
        guard let shotStartedAt else { return 0 }
        return max((shotStoppedAt ?? now).timeIntervalSince(shotStartedAt), 0)
    }

    var shotProgress: Double { min(shotElapsed / EspressoSetup.targetShotTime, 1) }
    var hasReachedTarget: Bool { shotElapsed >= EspressoSetup.targetShotTime }

    /// Refreshes the clock while the shot screen is visible.
    func run() async {
        await refreshWhileVisible { now = clock() }
    }

    func startShot() {
        guard !isShotRunning else { return }
        shotStartedAt = clock()
        shotStoppedAt = nil
        now = clock()
    }

    /// Stops the shot and moves on: milk / ice for drinks that need it, otherwise the result.
    func stopShot() {
        guard isShotRunning else { return }
        shotStoppedAt = clock()
        now = clock()
        shotTime = shotElapsed.rounded(.down)
        advance(to: draft.recipe.needsMilk || draft.recipe.needsIce ? .milk : .result)
    }

    // MARK: - Milk / ice

    /// "Steam wand", then your accessories (frothers).
    var frotherChoices: [String] {
        [tr("Steam wand")] + ownedAccessories.map(\.name)
    }

    func continueToResult() {
        if milk.frother.isEmpty { milk.frother = tr("Steam wand") }
        advance(to: .result)
    }

    // MARK: - Result

    /// The actual ratio once the shot was weighed.
    var actualRatio: Double? {
        guard let actualYield, actualYield > 0, draft.recipe.doseGrams > 0 else { return nil }
        return actualYield / draft.recipe.doseGrams
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let setup = draft.setup
        let trimmedMilk = MilkInfo(
            name: milk.name.trimmingCharacters(in: .whitespacesAndNewlines),
            temperature: milk.temperature,
            volumeMilliliters: milk.volumeMilliliters,
            frother: milk.frother
        )
        let trimmedIce = IceInfo(cubes: ice.cubes, mixer: ice.mixer.trimmingCharacters(in: .whitespacesAndNewlines))
        let brew = setup.makeBrew(
            shotTime: max(shotTime, 0),
            actualYieldGrams: actualYield,
            targetTDS: targetTDS,
            actualTDS: actualTDS,
            milk: trimmedMilk,
            ice: trimmedIce,
            tasting: tasting
        )
        alertMessage = await record(brew, in: brews, then: router)
        guard alertMessage == nil else { return }
        try? await suggestions.remember(Suggestions(
            milks: setup.needsMilk ? [trimmedMilk.name] : [],
            mixers: setup.needsIce ? [trimmedIce.mixer] : []
        ))
    }
}

/// An espresso in progress, passed by the flow from one step's screen to the next. The screens keep
/// the view model alive; the handle is made fresh for each step (so it's no retain cycle).
public final class EspressoBrew {
    let viewModel: EspressoViewModel

    init(viewModel: EspressoViewModel) {
        self.viewModel = viewModel
    }
}
