import Foundation
import Testing
@testable import Domain

struct DripperKindTests {
    @Test func classifiesNamesLikeTheWebApp() {
        #expect(DripperKind(deviceName: "Origami Dripper S") == .origami)
        #expect(DripperKind(deviceName: "CAFEC Flower Dripper 4 cup") == .flower)
        #expect(DripperKind(deviceName: "AeroPress Go") == .aeropress)
        #expect(DripperKind(deviceName: "Chemex 6-cup") == .chemex)
        #expect(DripperKind(deviceName: "Френч-прес Bodum") == .frenchPress)
        #expect(DripperKind(deviceName: "Hario Mizudashi 1L") == .coldBrew)
        #expect(DripperKind(deviceName: "Moccamaster KBGT-741") == .batch)
        #expect(DripperKind(deviceName: "Hario V60 02") == .cone)
        #expect(DripperKind(deviceName: "Kalita Wave 185") == .cone)
    }

    @Test func methodsOfferOnlyFittingDrippers() {
        #expect(DripperKind.aeropress.fits(.aeropress))
        #expect(!DripperKind.cone.fits(.aeropress))
        #expect(DripperKind.origami.fits(.v60))
        #expect(DripperKind.cone.fits(.v60))
        #expect(!DripperKind.chemex.fits(.v60))
        #expect(DripperKind.batch.fits(.batchBrewing))
    }
}

struct BrewSetupTests {
    @Test func defaultsMatchTheWebApp() {
        let setup = BrewSetup(method: .v60)
        #expect(setup.doseGrams == 16)
        #expect(setup.ratio == 16)
        #expect(setup.pours == 3)
        #expect(setup.grindSetting == 28)
        #expect(setup.waterTemperature == 93)
        #expect(setup.isFilterRinsed)
        #expect(setup.aeropress == nil)
    }

    @Test func methodSpecificDefaults() {
        #expect(BrewSetup(method: .coldBrew).waterTemperature == 18)
        #expect(BrewSetup.temperatureRange(for: .coldBrew) == 10...30)
        #expect(BrewSetup(method: .aeropress).aeropress == AeroPressOptions())
        #expect(!BrewSetup(method: .drip).usesDripper)
        #expect(!BrewSetup(method: .drip).usesFilter)
    }

    @Test func liveCalculation() {
        var setup = BrewSetup(method: .v60)
        setup.doseGrams = 15.5
        setup.ratio = 16.5
        #expect(setup.waterMilliliters == 256)
        #expect(setup.bloomMilliliters == 47)
    }

    @Test func validatedKeepsEveryValueInItsLimits() {
        var setup = BrewSetup(method: .coldBrew)
        setup.grindSetting = 0
        setup.waterTemperature = 93
        setup.doseGrams = 900
        setup.ratio = 15.96
        setup.pours = 9

        let valid = setup.validated()

        #expect(valid.grindSetting == 1)
        #expect(valid.waterTemperature == 30)
        #expect(valid.doseGrams == 300)
        #expect(valid.ratio == 16)
        #expect(valid.pours == 5)
        var aeropress = BrewSetup(method: .aeropress)
        aeropress.aeropress?.filterCount = 7
        #expect(aeropress.validated().aeropress?.filterCount == 4)
    }

    @Test func stockRules() {
        #expect(Bean(name: "a", totalGrams: 250, remainingGrams: 50).isLow)
        #expect(!Bean(name: "b", totalGrams: 250, remainingGrams: 51).isLow)
        #expect(FilterPack(name: "c", total: 100, remaining: 64).remainingFraction == 0.64)
        #expect(FilterPack(name: "d", total: 0).remainingFraction == 0)
    }

    @Test func ratioIsClampedAndRounded() {
        #expect(BrewSetup.validRatio(0.4) == 1)
        #expect(BrewSetup.validRatio(42) == 30)
        #expect(BrewSetup.validRatio(15.96) == 16)
    }

    @Test func brewKeepsGearTheMethodUses() {
        var setup = BrewSetup(method: .drip)
        setup.dripper = GearReference(name: "Hario V60 02")
        setup.filter = GearReference(name: "Melitta")
        setup.grinder = GearReference(name: "Comandante")
        setup.grindSetting = 24

        let brew = setup.makeBrew(rating: 8)

        #expect(brew.dripper == nil)
        #expect(brew.filter == nil)
        #expect(brew.isFilterRinsed == nil)
        #expect(brew.grinder?.name == "Comandante")
        #expect(brew.grindSetting == 24)
        #expect(brew.waterGrams == 256)
    }
}

struct BrewSetupPrefillTests {
    private let filterBag = Bean(name: "Kenya", roastProfile: .filter)
    private let espressoBag = Bean(name: "Brazil", roastProfile: .espresso)
    private let v60 = Device(name: "Hario V60 02", type: .dripper)
    private let aeropress = Device(name: "AeroPress Go", type: .dripper)
    private let grinder = Device(name: "Comandante C40", type: .grinder)
    private let pack = FilterPack(name: "Cafec", total: 100)

    private func prefill(_ method: BrewMethod, history: [BrewSetup] = [], beans: [Bean], drippers: [Device] = [], filters: [FilterPack] = [], grinders: [Device] = []) -> BrewSetupDraft {
        BrewSetupDraft(method: method, history: history, beans: beans, drippers: drippers, filters: filters, grinders: grinders)
    }

    @Test func onlyBagIsPickedWhateverItsRoast() {
        #expect(prefill(.v60, beans: [espressoBag]).bean == espressoBag)
    }

    @Test func bagFollowsTheRoastForTheBrew() {
        let beans = [filterBag, espressoBag]
        #expect(prefill(.chemex, beans: beans).bean == filterBag)
        #expect(prefill(.latte, beans: beans).bean == espressoBag)
        // Two that fit, no history: the user chooses.
        #expect(prefill(.v60, beans: beans + [Bean(name: "Omni", roastProfile: .omni)]).bean == nil)
    }

    @Test func emptyBagsAreSkipped() {
        let empty = Bean(name: "Done", totalGrams: 250, remainingGrams: 0, roastProfile: .filter)
        #expect(prefill(.v60, beans: [empty, espressoBag]).bean == espressoBag)
    }

    @Test func lastBagWinsWhileItFits() {
        let other = Bean(name: "Ethiopia", roastProfile: .filter)
        var last = BrewSetup(method: .chemex)
        last.bean = BeanReference(other)
        #expect(prefill(.v60, history: [last], beans: [filterBag, other]).bean == other)
        // An espresso drink doesn't take the filter brew's bag.
        #expect(prefill(.latte, history: [last], beans: [filterBag, other, espressoBag]).bean == espressoBag)
    }

    @Test func brewerFitsTheMethod() {
        #expect(prefill(.aeropress, beans: [], drippers: [v60, aeropress]).dripper == aeropress)
        #expect(prefill(.v60, beans: [], drippers: [aeropress, v60]).dripper == v60)
        #expect(prefill(.chemex, beans: [], drippers: [v60, aeropress]).dripper == nil)
        #expect(prefill(.drip, beans: [], drippers: [v60]).dripper == nil)
    }

    @Test func recipeAndGearComeFromTheLastBrewWithTheMethod() {
        let origami = Device(name: "Origami Dripper S", type: .dripper)
        let otherGrinder = Device(name: "Timemore C3", type: .grinder)
        var last = BrewSetup(method: .v60)
        last.dripper = GearReference(origami)
        last.grinder = GearReference(otherGrinder)
        last.filter = GearReference(pack)
        last.doseGrams = 20
        last.ratio = 15
        last.grindSetting = 22

        let result = prefill(.v60, history: [last], beans: [], drippers: [v60, origami], filters: [FilterPack(name: "Other"), pack], grinders: [grinder, otherGrinder])

        #expect(result.dripper == origami)
        #expect(result.grinder == otherGrinder)
        #expect(result.filter == pack)
        #expect(result.recipe.doseGrams == 20)
        #expect(result.recipe.ratio == 15)
        #expect(result.recipe.grindSetting == 22)
        #expect(result.setup.dripper?.id == origami.id)
    }

    @Test func otherMethodsKeepDefaultsButShareGrinder() {
        var last = BrewSetup(method: .v60)
        last.doseGrams = 20
        last.grinder = GearReference(grinder)

        let result = prefill(.chemex, history: [last], beans: [], grinders: [Device(name: "Other", type: .grinder), grinder])

        #expect(result.recipe.doseGrams == 16)
        #expect(result.grinder == grinder)
    }

    @Test func prefillKeepsWhatTheUserPickedAndSetupIsReady() {
        var edited = BrewSetupDraft(method: .v60)
        edited.bean = filterBag
        let prefilled = prefill(.v60, beans: [espressoBag], drippers: [v60])

        let merged = edited.keepingPicks(over: prefilled)

        #expect(merged.bean == filterBag)
        #expect(merged.dripper == v60)
        var tooMuch = merged
        tooMuch.recipe.doseGrams = 900
        #expect(tooMuch.setup.doseGrams == 300)
        #expect(tooMuch.setup.bean?.beanID == filterBag.id)
    }

    @Test func singleFilterPackWithFiltersIsPicked() {
        let empty = FilterPack(name: "Empty", total: 100, remaining: 0)
        #expect(prefill(.v60, beans: [], filters: [empty, pack]).filter == pack)
        #expect(prefill(.v60, beans: [], filters: [pack, FilterPack(name: "Second")]).filter == nil)
    }

    @Test func historyKeepsOnePerMethodNewestFirst() {
        var first = BrewSetup(method: .v60)
        first.doseGrams = 15
        let history = [first, BrewSetup(method: .chemex)].remembering(BrewSetup(method: .v60))

        #expect(history.map(\.method) == [.v60, .chemex])
        #expect(history.first?.doseGrams == 16)
    }
}

struct FilterShapeTests {
    @Test func packsFitTheirBrewer() {
        let chemex = FilterPack(name: "Chemex Bonded", shape: .chemex)
        let cone = FilterPack(name: "Cafec Abaca 02", shape: .cone)
        let unset = FilterPack(name: "Old pack")

        #expect(chemex.fits(.chemex))
        #expect(!chemex.fits(.v60))
        #expect(cone.fits(.v60))
        #expect(cone.fits(.batchBrewing))
        #expect(!cone.fits(.aeropress))
        #expect(unset.fits(.aeropress))
        #expect(chemex.fits(.frenchPress))
        #expect(FilterShape.shapes(for: .aeropress).first == .aeropress)
    }

    @Test func prefillOnlyPicksFittingPacks() {
        let chemex = FilterPack(name: "Chemex Bonded", shape: .chemex)
        let aeropress = FilterPack(name: "AeroPress papers", shape: .aeropress)

        let prefill = BrewSetupDraft(method: .chemex, history: [], beans: [], drippers: [], filters: [aeropress, chemex], grinders: [])

        #expect(prefill.filter == chemex)
    }

    @Test func packsSavedBeforeShapesExistedStillDecode() throws {
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(FilterPack(name: "Old", shape: .cone))) as! [String: Any]
        json.removeValue(forKey: "shape")

        let pack = try JSONDecoder().decode(FilterPack.self, from: JSONSerialization.data(withJSONObject: json))

        #expect(pack.name == "Old")
        #expect(pack.shape == nil)
    }
}
