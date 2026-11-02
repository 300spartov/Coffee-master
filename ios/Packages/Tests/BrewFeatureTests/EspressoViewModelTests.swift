import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import BrewFeature

@MainActor
final class SpyEspressoRouter: EspressoRouting {
    private(set) var steps: [EspressoStep] = []
    private(set) var saved: [Brew] = []
    private(set) var usages: [StockUsage] = []

    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void) {}
    func espresso(_ brew: EspressoBrew, didAdvanceTo step: EspressoStep) { steps.append(step) }
    func brewDidSave(_ brew: Brew, usage: StockUsage) { saved.append(brew); usages.append(usage) }
}

@Suite(.container)
@MainActor
struct EspressoViewModelTests {
    private let router = SpyEspressoRouter()

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    private func makeViewModel(_ method: BrewMethod, clock: Clock = Clock()) -> EspressoViewModel {
        EspressoViewModel(method: method, router: router, clock: { clock.now })
    }

    @Test func shotTimesFromTimestampsAndGoesToMilkForMilkDrinks() async {
        let clock = Clock()
        let latte = makeViewModel(.latte, clock: clock)
        await latte.startShotStep()

        latte.startShot()
        clock.now.addTimeInterval(28.6)
        latte.stopShot()

        #expect(latte.shot.shotTime == 28)
        #expect(latte.hasReachedTarget)
        #expect(router.steps == [.shot, .milk])

        latte.continueToResult()
        #expect(latte.shot.milk.frother == "Steam wand")
        #expect(router.steps.last == .result)
    }

    @Test func plainEspressoSkipsMilk() {
        let clock = Clock()
        let espresso = makeViewModel(.espresso, clock: clock)
        espresso.startShot()
        clock.now.addTimeInterval(25)
        espresso.stopShot()

        #expect(router.steps == [.result])
    }

    @Test func saveStoresTheShotAndRemembersTheMilk() async throws {
        let brews = TestRepository(brews: [])
        let suggestions = InMemorySuggestionsRepository()
        Container.shared.brewRepository.register { brews }
        Container.shared.suggestionsRepository.register { suggestions }
        let latte = makeViewModel(.latte)
        latte.shot.shotTime = 27
        latte.shot.actualYield = 38
        latte.shot.milk.name = "  Oat "
        latte.shot.tasting.rating = 9

        await latte.save()

        let saved = try #require(await brews.saved.first)
        #expect(saved.method == .latte)
        #expect(saved.espresso?.actualYieldGrams == 38)
        #expect(saved.milk?.name == "Oat")
        #expect(saved.rating == 9)
        #expect(router.saved.map(\.id) == [saved.id])
        #expect(try await suggestions.suggestions().milks == ["Oat"])
        #expect(latte.actualRatio.map { ($0 * 10).rounded() / 10 } == 2.1)
    }

    @Test func picksAndAccessories() async {
        let wdt = Device(name: "WDT", type: .accessory)
        Container.shared.deviceRepository.register { TestRepository(devices: [wdt]) }
        Container.shared.beanRepository.register { TestRepository(beans: []) }
        let viewModel = makeViewModel(.espresso)
        await viewModel.prefill()

        viewModel.apply(.device(Device(name: "Rancilio Silvia", type: .espressoMachine)))
        viewModel.apply(.device(Device(name: "Hario V60 02", type: .dripper)))
        viewModel.accessorySelection = [wdt.id]

        #expect(viewModel.draft.machine?.name == "Rancilio Silvia")
        #expect(viewModel.draft.grinder == nil)
        #expect(viewModel.draft.setup.accessories.map(\.name) == ["WDT"])
    }
}
