import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import BrewFeature

/// ROADMAP 2.8: the brew in progress survives an app kill.
@Suite(.container)
@MainActor
struct BrewInProgressTests {
    private let store = InMemoryDraftStore()
    private let t0 = Date(timeIntervalSince1970: 1_000)

    init() {
        Container.shared.draftStore.register { [store] in store }
    }

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    @Test func timerIsKeptOnceStartedAndRestoredWithItsClock() throws {
        let clock = Clock()
        let router = SpyActiveRouter()
        let viewModel = ActiveBrewViewModel(setup: BrewSetup(method: .v60), router: router, clock: { clock.now })
        #expect(BrewInProgress.current(now: t0) == nil)

        viewModel.pour()
        viewModel.currentPour = 55

        let draft = try #require(BrewInProgress.current(now: t0))
        guard case .timer(let session, let currentPour) = draft.stage else { Issue.record("Not a timer draft"); return }
        #expect(currentPour == 55)

        // "Relaunch" 90 s later: the clock is still right.
        clock.now.addTimeInterval(90)
        let restored = ActiveBrewViewModel(session: session, currentPour: currentPour, router: router, clock: { clock.now })
        restored.refresh()
        #expect(restored.session.elapsed(at: restored.now) == 90)
        #expect(restored.session.isPouring)
    }

    @Test func ratingIsKeptWithEditsAndTasting() throws {
        var session = PourOverSession(setup: BrewSetup(method: .v60))
        session.pour(at: t0)
        session.stop(poured: 200, at: t0.addingTimeInterval(60))
        let viewModel = RateBrewViewModel(session: session, router: SpyRateRouter())

        viewModel.setPour(at: 0, milliliters: 210)
        viewModel.tasting.rating = 9

        let draft = try #require(BrewInProgress.current())
        guard case .rating(_, let steps, let tasting) = draft.stage else { Issue.record("Not a rating draft"); return }
        #expect(steps.pours == [210])
        #expect(tasting.rating == 9)
    }

    @Test func espressoIsKeptFromTheShotAndRestored() async throws {
        let clock = Clock()
        let router = SpyEspressoRouter()
        let viewModel = EspressoViewModel(method: .latte, router: router, clock: { clock.now })
        await viewModel.startShotStep()
        viewModel.startShot()
        clock.now.addTimeInterval(27)
        viewModel.stopShot()
        viewModel.shot.milk.name = "Oat"

        let draft = try #require(BrewInProgress.current(now: clock.now))
        guard case .espresso(let progress) = draft.stage else { Issue.record("Not an espresso draft"); return }
        #expect(progress.step == .milk)
        #expect(progress.shot.shotTime == 27)

        let restored = EspressoViewModel(progress: progress, router: router)
        #expect(progress.shot.milk.frother == "Steam wand")
        #expect(restored.shot.milk.name == "Oat")
        #expect(restored.shotElapsed == 27)
        #expect(restored.draft.recipe.method == .latte)
    }

    @Test func oldDraftsAreDropped() {
        BrewInProgress.save(.timer(PourOverSession(setup: BrewSetup(method: .v60)), currentPour: nil), now: t0)

        #expect(BrewInProgress.current(now: t0.addingTimeInterval(3_600)) != nil)
        #expect(BrewInProgress.current(now: t0.addingTimeInterval(13 * 3_600)) == nil)
        #expect(store.data(for: BrewInProgress.key) == nil)
    }

    @Test func moduleRebuildsTheStepsAndDiscards() {
        var session = PourOverSession(setup: BrewSetup(method: .v60))
        session.pour(at: .now)
        BrewInProgress.save(.timer(session, currentPour: nil))
        let module = BrewModule()

        #expect(module.makeBrewInProgress(router: SpyWizardRouter())?.count == 2)
        module.discardBrewInProgress()
        #expect(!module.hasBrewInProgress)
        #expect(module.makeBrewInProgress(router: SpyWizardRouter()) == nil)
    }
}

@MainActor
final class SpyRateRouter: BrewSavingRouting, ActiveBrewRouting {
    func brewDidSave(_ brew: Brew, usage: StockUsage) {}
    func activeBrewDidFinish(_ session: PourOverSession) {}
    func brewDidDiscard() {}
}

@MainActor
final class SpyWizardRouter: MethodPickRouting, ActiveBrewRouting, EspressoRouting {
    func showMethods(in group: MethodGroup) {}
    func methodPickDidSelect(_ method: BrewMethod) {}
    func methodPickDidCancel() {}
    func methodPickDidSelectLog() {}
    func activeBrewDidFinish(_ session: PourOverSession) {}
    func brewDidDiscard() {}
    func brewDidSave(_ brew: Brew, usage: StockUsage) {}
    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void) {}
    func espresso(_ brew: EspressoBrew, didAdvanceTo step: EspressoStep) {}
}
