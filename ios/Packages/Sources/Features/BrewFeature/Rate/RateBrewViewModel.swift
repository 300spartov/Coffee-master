import Foundation
import Observation
import Domain
import FactoryKit

/// Wizard's last step for pour-over (web: `bv-rate` → `saveBrew`): correct the pours, rate, describe the
/// taste, save. Saving records the brew and takes its dose and a filter from stock.
@Observable
final class RateBrewViewModel {
    let setup: BrewSetup
    let totalTime: TimeInterval
    /// The timer's log; pours can be corrected here.
    private(set) var steps: [BrewStep] {
        didSet { persist() }
    }
    var tasting = BrewTasting() {
        didSet { persist() }
    }
    /// Back was tapped: leaving discards the brew.
    var isConfirmingLeave = false
    @ObservationIgnored private let session: PourOverSession
    private(set) var isSaving = false
    var alertMessage: String?

    @ObservationIgnored @Injected(\.brewRepository) private var brews
    @ObservationIgnored private weak var router: (any BrewSavingRouting & ActiveBrewRouting)?

    /// `steps` / `tasting`: a rating in progress restored after an app kill.
    init(session: PourOverSession, steps: [BrewStep]? = nil, tasting: BrewTasting = BrewTasting(), router: any BrewSavingRouting & ActiveBrewRouting) {
        self.session = session
        setup = session.setup
        totalTime = session.elapsed(at: .now).rounded(.down)
        self.steps = steps ?? session.steps
        self.tasting = tasting
        self.router = router
        persist()
    }

    func didTapBack() {
        isConfirmingLeave = true
    }

    func leave() {
        router?.activeBrewDidLeave()
    }

    private func persist() {
        BrewInProgress.save(.rating(session, steps: steps, tasting: tasting))
    }

    var pouredMilliliters: Double { steps.totalPouredMilliliters }

    /// Corrects one pour (index into `steps`).
    func setPour(at index: Int, milliliters: Double) {
        steps.setPour(at: index, milliliters: milliliters)
    }

    /// The total poured; setting it spreads the water evenly over the pours (like the web app).
    var totalPoured: Double {
        get { pouredMilliliters }
        set { steps.spreadPours(newValue) }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        alertMessage = await record(setup.makeBrew(totalTime: totalTime, steps: steps, tasting: tasting), in: brews, then: router)
    }
}
