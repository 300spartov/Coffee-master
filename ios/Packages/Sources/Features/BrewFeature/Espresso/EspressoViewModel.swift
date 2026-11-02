import Foundation
import AppCore
import Observation
import Domain
import FactoryKit

/// One espresso from setup to saved shot, shared by its four screens (setup → shot → milk / ice →
/// result), like the web app's single brew state. The shot clock keeps timestamps.
@Observable
final class EspressoViewModel: GearPickingModel, SavingViewModel {
    let method: BrewMethod
    var draft: EspressoDraft
    /// Owned accessories, for the accessory chips and the milk frother.
    private(set) var ownedAccessories: [Device] = []
    private(set) var milkSuggestions: [String] = []
    private(set) var mixerSuggestions: [String] = []

    /// The step on screen after the setup (nil on the setup); from then on the brew is kept.
    private(set) var step: EspressoStep? { didSet { persist() } }
    /// The shot, milk / ice and the result, kept with every change.
    var shot = EspressoShotState() { didSet { persist() } }
    private(set) var now: Date
    var isSaving = false
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
        shot = progress.shot
        step = progress.step
    }

    /// Shows `step` (the flow pushes its screen) and keeps the brew from then on.
    private func advance(to step: EspressoStep) {
        self.step = step
        router?.espresso(EspressoBrew(viewModel: self), didAdvanceTo: step)
    }

    private func persist() {
        guard let step else { return }
        BrewInProgress.save(.espresso(EspressoProgress(step: step, draft: draft, shot: shot)))
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

    /// Back on the setup from the shot: like pour-over, a brew left before it's done is dropped (the
    /// shot starts over and nothing is kept for an app kill).
    func didReturnToSetup() {
        guard step != nil else { return }
        step = nil
        shot = EspressoShotState()
        BrewInProgress.discard()
    }

    /// Remembers the recipe for next time and goes to the shot.
    func startShotStep() async {
        await history.remember(draft.setup)
        advance(to: .shot)
    }

    // MARK: - Shot

    var isShotRunning: Bool { shot.startedAt != nil && shot.stoppedAt == nil }

    var shotElapsed: TimeInterval {
        guard let startedAt = shot.startedAt else { return 0 }
        return max((shot.stoppedAt ?? now).timeIntervalSince(startedAt), 0)
    }

    var shotProgress: Double { min(shotElapsed / EspressoSetup.targetShotTime, 1) }
    var hasReachedTarget: Bool { shotElapsed >= EspressoSetup.targetShotTime }

    /// Refreshes the clock while the shot screen is visible.
    func run() async {
        await refreshWhileVisible { now = clock() }
    }

    func startShot() {
        guard !isShotRunning else { return }
        shot.startedAt = clock()
        shot.stoppedAt = nil
        now = clock()
    }

    /// Stops the shot and moves on: milk / ice for drinks that need it (the frother starts as the steam
    /// wand), otherwise the result.
    func stopShot() {
        guard isShotRunning else { return }
        shot.stoppedAt = clock()
        now = clock()
        shot.shotTime = shotElapsed.rounded(.down)
        if shot.milk.frother.isEmpty { shot.milk.frother = frotherChoices[0] }
        advance(to: draft.recipe.needsMilk || draft.recipe.needsIce ? .milk : .result)
    }

    // MARK: - Milk / ice

    /// "Steam wand", then your accessories (frothers).
    var frotherChoices: [String] {
        [tr("Steam wand")] + ownedAccessories.map(\.name)
    }

    func continueToResult() {
        advance(to: .result)
    }

    // MARK: - Result

    /// The actual ratio once the shot was weighed.
    var actualRatio: Double? {
        guard let actualYield = shot.actualYield, actualYield > 0, draft.recipe.doseGrams > 0 else { return nil }
        return actualYield / draft.recipe.doseGrams
    }

    func save() async {
        await whileSaving {
            let setup = draft.setup
            let brew = setup.makeBrew(
                shotTime: max(shot.shotTime, 0),
                actualYieldGrams: shot.actualYield,
                targetTDS: shot.targetTDS,
                actualTDS: shot.actualTDS,
                milk: shot.milk,
                ice: shot.ice,
                tasting: shot.tasting
            )
            guard await record(brew, in: brews, then: router) else { return }
            try? await suggestions.remember(Suggestions(milks: brew.milk.map { [$0.name] } ?? [], mixers: brew.ice.map { [$0.mixer] } ?? []))
        }
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
