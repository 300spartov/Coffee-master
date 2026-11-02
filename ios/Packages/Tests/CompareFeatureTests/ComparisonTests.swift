import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import CompareFeature

struct ComparisonTests {
    private let pourOver = Brew(method: .v60, doseGrams: 16, ratio: 16, waterTemperature: 93, steps: [
        BrewStep(kind: .pour(milliliters: 60), start: 0, duration: 10),
        BrewStep(kind: .pause, start: 12, duration: 30),
        BrewStep(kind: .action(.stir), start: 40, duration: 10),
        BrewStep(kind: .pour(milliliters: 196), start: 50, duration: 20),
    ], rating: 8)

    @Test func stepsRunBackToBackIntoTheCurve() {
        let entry = Comparison(brews: [pourOver]).entries[0]

        #expect(entry.totalTime == 70)
        #expect(entry.curve.map(\.seconds) == [0, 10, 40, 50, 70])
        #expect(entry.curve.map(\.milliliters) == [0, 60, 60, 60, 256])
        #expect(entry.actions == [Comparison.CurvePoint(seconds: 45, milliliters: 60)])
    }

    @Test func espressoWithoutStepsIsItsShot() {
        let shot = Brew(method: .espresso, doseGrams: 18, ratio: 2, espresso: EspressoShot(doseGrams: 18, targetYieldGrams: 36, shotTime: 27), rating: 8)

        let entry = Comparison(brews: [shot]).entries[0]

        #expect(entry.steps == [BrewStep(kind: .pour(milliliters: 36), start: 0, duration: 27)])
    }

    @Test func rowsMarkTheOddOneOut() {
        var stronger = pourOver
        stronger.doseGrams = 18
        var third = pourOver
        third.waterTemperature = 90

        let rows = Comparison(brews: [pourOver, stronger, third]).rows
        let dose = rows.first { $0.title == "Dose" }
        let method = rows.first { $0.title == "Method" }

        #expect(dose?.values == ["16 g", "18 g", "16 g"])
        #expect(dose?.differs == [false, true, false])
        #expect(method?.differs == [false, false, false])
        #expect(rows.first { $0.title == "First pour" }?.values == ["60 ml", "60 ml", "60 ml"])
    }

    @Test func upToFourBrews() {
        #expect(Comparison(brews: Array(repeating: pourOver, count: 6)).entries.map(\.index) == [0, 1, 2, 3])
    }
}

@Suite(.container)
@MainActor
struct CompareViewModelTests {
    @Test func loadsThePickedBrewsInPickOrderSkippingMissing() async {
        Container.shared.brewRepository.register { TestRepository(brews: Brew.samples) }
        let viewModel = CompareViewModel(brewIDs: [Brew.samples[2].id, UUID(), Brew.samples[0].id])

        await viewModel.load()

        #expect(viewModel.comparison.entries.map(\.id) == [Brew.samples[2].id, Brew.samples[0].id])
        #expect(viewModel.state == .ready)
    }

    @Test func highlightFadesTheOthers() {
        let viewModel = CompareViewModel(brewIDs: [])
        let entries = Comparison(brews: Array(Brew.samples.prefix(2))).entries

        viewModel.toggleHighlight(entries[0])
        #expect(!viewModel.isFaded(entries[0]) && viewModel.isFaded(entries[1]))
        viewModel.toggleHighlight(entries[0])
        #expect(!viewModel.isFaded(entries[1]))
    }
}
