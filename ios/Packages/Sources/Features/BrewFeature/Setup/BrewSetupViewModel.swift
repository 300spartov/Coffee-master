import Foundation
import Observation
import Domain
import FactoryKit

/// Wizard step 3 for alternative methods: gear and recipe, with the live water calculation.
@Observable
final class BrewSetupViewModel {
    let method: BrewMethod
    /// The screen edits `draft.recipe`; the picker sets the gear.
    var draft: BrewSetupDraft
    /// Start is running (remembering the setup), so a double tap starts once.
    private(set) var isStarting = false

    /// Prefill runs once; coming back to the screen keeps what the user changed.
    @ObservationIgnored private var didPrefill = false
    @ObservationIgnored @Injected(\.brewSetupHistory) private var history
    @ObservationIgnored private weak var router: (any BrewSetupRouting)?

    init(method: BrewMethod, router: any BrewSetupRouting) {
        self.method = method
        self.router = router
        draft = BrewSetupDraft(method: method)
    }

    /// Starts from the last brew with this method and picks gear you have (`BrewSetupDraft`).
    /// Gear the user already picked is kept.
    func prefill() async {
        guard !didPrefill else { return }
        didPrefill = true
        draft = draft.keepingPicks(over: await BrewSetupDraft.prefilled(for: method))
    }

    var temperatureRange: ClosedRange<Double> { BrewSetup.temperatureRange(for: method) }

    /// The picked item for a setup row, as the picker shows it.
    func picked(_ kind: GearKind) -> GearPickerViewModel.Row? {
        switch kind {
        case .bean: draft.bean.map(GearPickerViewModel.Row.init(bean:))
        case .dripper: draft.dripper.map { .init(device: $0, kind: .dripper) }
        case .filter: draft.filter.map(GearPickerViewModel.Row.init(filterPack:))
        case .grinder: draft.grinder.map { .init(device: $0, kind: .grinder) }
        }
    }

    // MARK: - Actions

    func choose(_ kind: GearKind) {
        router?.showGearPicker(kind, method: method, selectedID: picked(kind)?.ownedID) { [weak self] pick in
            self?.apply(pick)
        }
    }

    func apply(_ pick: GearPick) {
        switch pick {
        case .bean(let bean): draft.bean = bean
        case .filterPack(let pack): draft.filter = pack
        case .device(let device):
            if device.type == .grinder { draft.grinder = device } else { draft.dripper = device }
        }
    }

    /// Remembers the setup for next time, then starts.
    func start() async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        let setup = draft.setup
        await history.remember(setup)
        router?.brewSetupDidStart(setup)
    }
}
