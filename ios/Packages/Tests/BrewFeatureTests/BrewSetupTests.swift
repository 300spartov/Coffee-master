import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import BrewFeature

@MainActor
final class SpySetupRouter: BrewSetupRouting, GearPickerRouting {
    private(set) var pickerRequests: [(kind: GearKind, selectedID: UUID?)] = []
    private(set) var started: [BrewSetup] = []
    private(set) var picks: [GearPick] = []
    private(set) var addRequests: [GearKind] = []
    /// The last picker's callback, so a test can "pick" something.
    private(set) var onPick: ((GearPick) -> Void)?

    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void) {
        pickerRequests.append((kind, selectedID))
        self.onPick = onPick
    }

    func brewSetupDidStart(_ setup: BrewSetup) { started.append(setup) }
    func gearPickerDidPick(_ pick: GearPick) { picks.append(pick) }
    func gearPickerDidTapAdd(_ kind: GearKind) { addRequests.append(kind) }
}

@Suite(.container)
@MainActor
struct BrewSetupViewModelTests {
    private let router = SpySetupRouter()

    @Test func pickedGearGoesIntoTheSetup() throws {
        let viewModel = BrewSetupViewModel(method: .v60, router: router)

        viewModel.choose(.bean)
        let pickBean = try #require(router.onPick)
        pickBean(.bean(Bean.samples[0]))
        viewModel.choose(.grinder)
        let pickGrinder = try #require(router.onPick)
        pickGrinder(.device(Device.samples[2]))
        viewModel.choose(.bean)

        #expect(viewModel.draft.setup.bean?.beanID == Bean.samples[0].id)
        #expect(viewModel.draft.setup.grinder?.id == Device.samples[2].id)
        #expect(router.pickerRequests.map(\.kind) == [.bean, .grinder, .bean])
        #expect(router.pickerRequests.last?.selectedID == Bean.samples[0].id)
    }

    @Test func startSendsTheSetupWithinLimits() async {
        let viewModel = BrewSetupViewModel(method: .aeropress, router: router)
        viewModel.draft.recipe.doseGrams = 18
        viewModel.draft.recipe.ratio = 15.96
        viewModel.draft.recipe.grindSetting = 500
        viewModel.draft.recipe.aeropress?.isInverted = true
        viewModel.draft.recipe.aeropress?.filterCount = 2

        await viewModel.start()

        let setup = router.started.first
        #expect(setup?.method == .aeropress)
        #expect(setup?.ratio == 16)
        #expect(setup?.grindSetting == 200)
        #expect(setup?.waterMilliliters == 288)
        #expect(setup?.aeropress == AeroPressOptions(isInverted: true, filterCount: 2))
    }

    @Test func prefillPicksFittingGearAndStartRemembers() async {
        let history = InMemoryBrewSetupHistory()
        let aeropress = Device(name: "AeroPress Go", type: .dripper)
        Container.shared.brewSetupHistory.register { history }
        Container.shared.beanRepository.register { TestRepository(beans: [Bean(name: "Kenya", roastProfile: .filter)]) }
        Container.shared.deviceRepository.register { TestRepository(devices: [Device(name: "Hario V60 02", type: .dripper), aeropress]) }
        Container.shared.filterPackRepository.register { TestRepository(filterPacks: []) }
        let viewModel = BrewSetupViewModel(method: .aeropress, router: router)

        await viewModel.prefill()
        #expect(viewModel.draft.bean?.name == "Kenya")
        #expect(viewModel.draft.dripper?.id == aeropress.id)
        viewModel.draft.recipe.doseGrams = 17
        viewModel.draft.recipe.aeropress?.isInverted = true
        await viewModel.start()

        // Next time: same recipe, and prefill doesn't run twice on one screen.
        let next = BrewSetupViewModel(method: .aeropress, router: router)
        await next.prefill()
        #expect(next.draft.recipe.doseGrams == 17)
        #expect(next.draft.recipe.aeropress?.isInverted == true)
        next.draft.recipe.doseGrams = 19
        await next.prefill()
        #expect(next.draft.recipe.doseGrams == 19)
        #expect(await history.recentSetups().map(\.method) == [.aeropress])
    }

    @Test func doubleTapOnStartStartsOnce() async {
        let viewModel = BrewSetupViewModel(method: .v60, router: router)

        async let first: Void = viewModel.start()
        async let second: Void = viewModel.start()
        _ = await (first, second)

        #expect(router.started.count == 1)
    }
}

@Suite(.container)
@MainActor
struct GearPickerViewModelTests {
    private let router = SpySetupRouter()

    private func makeViewModel(_ kind: GearKind, method: BrewMethod = .v60, devices: [Device] = [], filterPacks: [FilterPack] = FilterPack.samples) -> (GearPickerViewModel, TestRepository<Device>) {
        let repository = TestRepository(devices: devices)
        Container.shared.deviceRepository.register { repository }
        Container.shared.beanRepository.register { TestRepository(beans: Bean.samples) }
        Container.shared.filterPackRepository.register { TestRepository(filterPacks: filterPacks) }
        return (GearPickerViewModel(kind: kind, method: method, selectedID: nil, router: router), repository)
    }

    @Test func listsBeansWithStock() async {
        let (viewModel, _) = makeViewModel(.bean)

        await viewModel.load()

        #expect(viewModel.owned.map(\.title) == Bean.samples.map(\.name))
        #expect(viewModel.owned.first?.subtitle == "Wonder&Full · 160 / 250 g")
        #expect(viewModel.owned.first?.stock?.fraction == 0.64)
        #expect(viewModel.suggestions.isEmpty)
    }

    @Test func aeropressOffersOnlyAeropresses() async {
        let devices = [Device(name: "Hario V60 02", type: .dripper), Device(name: "AeroPress Go", type: .dripper)]
        let (viewModel, _) = makeViewModel(.dripper, method: .aeropress, devices: devices)

        await viewModel.load()

        #expect(viewModel.owned.map(\.title) == ["AeroPress Go"])
        #expect(viewModel.owned.first?.dripperKind == .aeropress)
    }

    @Test func withoutFittingDevicesOffersCatalogAndAddsThePick() async throws {
        let (viewModel, repository) = makeViewModel(.dripper, method: .chemex, devices: [Device(name: "Hario V60 02", type: .dripper)])
        await viewModel.load()
        #expect(viewModel.owned.isEmpty)
        #expect(viewModel.suggestions.map(\.title) == ["Chemex 3-cup", "Chemex 6-cup", "Chemex 8-cup"])

        await viewModel.didSelect(viewModel.suggestions[1])

        // Saving stamps `updatedAt`, so compare by ID.
        let added = try #require(try await repository.fetchAll(of: .dripper).first { $0.name == "Chemex 6-cup" })
        guard case .device(let picked) = router.picks.first else { Issue.record("Nothing picked"); return }
        #expect(picked.id == added.id)
    }

    @Test func filterPacksForOtherBrewersAreListedSeparately() async {
        let chemex = FilterPack(name: "Chemex Bonded", shape: .chemex)
        let cone = FilterPack(name: "Cafec Abaca 02", shape: .cone)
        let unset = FilterPack(name: "Old pack")
        let (viewModel, _) = makeViewModel(.filter, method: .chemex, filterPacks: [cone, unset, chemex])

        await viewModel.load()

        #expect(Set(viewModel.owned.map(\.title)) == ["Chemex Bonded", "Old pack"])
        #expect(viewModel.others.map(\.title) == ["Cafec Abaca 02"])
        #expect(viewModel.owned.first { $0.title == "Chemex Bonded" }?.subtitle == "Chemex · 100 of 100 left")
    }

    @Test func pickingOwnedRoutesItAndAddRoutes() async {
        let (viewModel, _) = makeViewModel(.filter)
        await viewModel.load()

        await viewModel.didSelect(viewModel.owned[1])
        viewModel.didTapAdd()

        #expect(router.picks == [.filterPack(FilterPack.samples[1])])
        #expect(router.addRequests == [.filter])
    }
}
