import Foundation
import Testing
@testable import Domain

struct EspressoSetupTests {
    @Test func defaultsAndDrinkSteps() {
        let setup = EspressoSetup(method: .latte)
        #expect(setup.doseGrams == 18)
        #expect(setup.ratio == 2)
        #expect(setup.targetYieldGrams == 36)
        #expect(setup.waterTemperature == 93)
        #expect(setup.pressureBar == 9)
        #expect(setup.needsMilk && !setup.needsIce)
        #expect(EspressoSetup(method: .espressoTonic).needsIce)
        #expect(!EspressoSetup(method: .espresso).needsMilk)
    }

    @Test func validatedKeepsLimitsAndRoundsTheRatio() {
        var setup = EspressoSetup()
        setup.doseGrams = 40
        setup.ratio = 2.26
        setup.pressureBar = 15
        let valid = setup.validated()
        #expect(valid.doseGrams == 30)
        #expect(valid.ratio == 2.3)
        #expect(valid.pressureBar == 12)
    }

    @Test func brewRecordsTheShotWithActualRatio() {
        var setup = EspressoSetup(method: .cappuccino)
        setup.machine = GearReference(name: "Gaggia Classic Pro")
        setup.accessories = [GearReference(id: .fixture(9), name: "WDT")]
        let milk = MilkInfo(name: "Oat", temperature: 60, volumeMilliliters: 150, frother: "Steam wand")

        let brew = setup.makeBrew(shotTime: 28, actualYieldGrams: 40, targetTDS: 9, actualTDS: nil, milk: milk, ice: IceInfo(cubes: 4), tasting: BrewTasting(rating: 8.5, notes: " Sweet "))

        #expect(brew.method == .cappuccino)
        #expect(brew.espresso?.actualYieldGrams == 40)
        #expect(brew.espresso?.targetYieldGrams == 36)
        #expect(brew.ratio == 40.0 / 18)
        #expect(brew.totalTime == 28)
        #expect(brew.milk == milk)
        #expect(brew.ice == nil)
        #expect(brew.espressoMachine?.name == "Gaggia Classic Pro")
        #expect(brew.accessoryIDs == [.fixture(9)])
        #expect(brew.category == .espresso)
        #expect(brew.rating == 8.5)
        #expect(brew.notes == "Sweet")
    }

    @Test func unweighedShotKeepsThePlannedRatio() {
        let brew = EspressoSetup().makeBrew(shotTime: 25, actualYieldGrams: 0, targetTDS: nil, actualTDS: nil, milk: nil, ice: nil, tasting: BrewTasting(rating: 7))
        #expect(brew.espresso?.actualYieldGrams == nil)
        #expect(brew.ratio == 2)
    }

    @Test func iceSavedUnderTheOldKeyStillLoads() throws {
        let legacy = Data(#"{"amountGrams":4,"mixer":"Tonic"}"#.utf8)
        let ice = try JSONDecoder().decode(IceInfo.self, from: legacy)
        #expect(ice.cubes == 4)
        #expect(ice.mixer == "Tonic")
    }
}

struct EspressoDraftTests {
    private let espressoBag = Bean(name: "Brazil", roastProfile: .espresso)
    private let filterBag = Bean(name: "Kenya", roastProfile: .filter)
    private let machine = Device(name: "Gaggia Classic Pro", type: .espressoMachine)
    private let grinder = Device(name: "Niche Zero", type: .grinder)
    private let wdt = Device(name: "WDT", type: .accessory)
    private let tamper = Device(name: "Tamper", type: .accessory)

    @Test func prefillPicksEspressoGear() {
        let draft = EspressoDraft(method: .latte, history: [], pourOverHistory: [], beans: [filterBag, espressoBag], devices: [machine, grinder, wdt])

        #expect(draft.bean == espressoBag)
        #expect(draft.machine == machine)
        #expect(draft.grinder == grinder)
        #expect(draft.accessories.isEmpty)
        #expect(draft.recipe.method == .latte)
    }

    @Test func lastShotRecipeAndAccessoriesAreRestored() {
        var last = EspressoSetup(method: .espresso)
        last.doseGrams = 20
        last.accessories = [GearReference(wdt)]

        let draft = EspressoDraft(method: .latte, history: [last], pourOverHistory: [], beans: [], devices: [machine, wdt, tamper])

        #expect(draft.recipe.doseGrams == 20)
        #expect(draft.recipe.method == .latte)
        #expect(draft.accessories == [wdt])
        #expect(draft.setup.accessories.map(\.id) == [wdt.id])
    }

    @Test func grinderFromPourOverHistoryCounts() {
        let other = Device(name: "Comandante", type: .grinder)
        var pourOver = BrewSetup(method: .v60)
        pourOver.grinder = GearReference(other)

        let draft = EspressoDraft(method: .espresso, history: [], pourOverHistory: [pourOver], beans: [], devices: [grinder, other])

        #expect(draft.grinder == other)
    }
}
