import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import BrewFeature

@MainActor
final class SpySavingRouter: BrewSavingRouting {
    private(set) var saved: [(brew: Brew, usage: StockUsage)] = []
    func brewDidSave(_ brew: Brew, usage: StockUsage) { saved.append((brew, usage)) }
}

@Suite(.container)
@MainActor
struct RateBrewViewModelTests {
    private let router = SpySavingRouter()
    private let t0 = Date(timeIntervalSince1970: 1_000)

    /// Bloom 50 ml, a stir, then 200 ml; stopped at 2:30.
    private func finishedSession() -> PourOverSession {
        var setup = BrewSetup(method: .v60)
        setup.bean = BeanReference(beanID: .fixture(1), name: "Kenya")
        var session = PourOverSession(setup: setup)
        session.pour(at: t0)
        session.pause(poured: 50, at: t0.addingTimeInterval(10))
        session.startAction(.stir, at: t0.addingTimeInterval(20))
        session.finishAction(at: t0.addingTimeInterval(25))
        session.pour(at: t0.addingTimeInterval(40))
        session.pause(poured: 200, at: t0.addingTimeInterval(70))
        session.stop(at: t0.addingTimeInterval(150))
        return session
    }

    @Test func showsTheTimerResults() {
        let viewModel = RateBrewViewModel(session: finishedSession(), router: router)

        #expect(viewModel.totalTime == 150)
        #expect(viewModel.pouredMilliliters == 250)
        #expect(viewModel.steps.count == 6)
    }

    @Test func poursCanBeCorrectedOneByOneOrAsATotal() {
        let viewModel = RateBrewViewModel(session: finishedSession(), router: router)

        viewModel.setPour(at: 0, milliliters: 60)
        #expect(viewModel.pouredMilliliters == 260)
        viewModel.setPour(at: 1, milliliters: 99) // a pause: ignored
        #expect(viewModel.pouredMilliliters == 260)

        viewModel.totalPoured = 255
        #expect(viewModel.steps.pours == [127.5, 127.5])
    }

    @Test func saveRecordsTheBrewWithTasteAndRoutesTheStock() async throws {
        let brews = TestRepository(brews: [])
        let usage = StockUsage(bean: Bean(name: "Kenya", totalGrams: 250, remainingGrams: 0))
        await brews.setUsage(usage)
        Container.shared.brewRepository.register { brews }
        let viewModel = RateBrewViewModel(session: finishedSession(), router: router)
        viewModel.tasting = BrewTasting(rating: 9.1, flavors: ["Манго"], aromas: ["Жасмин"], notes: " Juicy ")

        await viewModel.save()

        let saved = try #require(await brews.saved.first)
        #expect(saved.method == .v60)
        #expect(saved.bean?.name == "Kenya")
        #expect(saved.rating == 9.1)
        #expect(saved.totalTime == 150)
        #expect(saved.steps.count == 6)
        #expect(saved.flavors == ["Манго"])
        #expect(saved.aromas == ["Жасмин"])
        #expect(saved.notes == "Juicy")
        #expect(router.saved.first?.usage == usage)
    }

    @Test func failedSaveShowsAnAlert() async {
        Container.shared.brewRepository.register { TestRepository(brews: [], failing: .writes) }
        let viewModel = RateBrewViewModel(session: finishedSession(), router: router)

        await viewModel.save()

        #expect(viewModel.alertMessage == "Boom")
        #expect(router.saved.isEmpty)
    }
}
