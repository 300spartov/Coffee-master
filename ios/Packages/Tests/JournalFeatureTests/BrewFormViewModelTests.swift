import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import JournalFeature

@Suite(.container)
@MainActor
struct BrewFormViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(_ brew: Brew, repository: TestRepository<Brew>? = nil) -> (BrewFormViewModel, TestRepository<Brew>) {
        let repository = repository ?? TestRepository(brews: [brew])
        Container.shared.brewRepository.register { repository }
        return (BrewFormViewModel(mode: .edit(brew.id), router: router), repository)
    }

    @Test func editedStepsAndTastingAreSaved() async throws {
        let (viewModel, repository) = makeViewModel(Brew.samples[0])
        await viewModel.load()

        viewModel.removeSteps(at: [1])                 // the first pause
        viewModel.setPour(false, at: 2)                // the swirl stays an action
        viewModel.setPour(false, at: 1)                // pour 100 ml → pause
        viewModel.addStep()                            // + pour 50 ml, 15 s
        viewModel.brew.tasting.rating = 6.5
        viewModel.brew.tasting.notes = "Flat. "
        await viewModel.save()

        let saved = try await repository.fetch(id: Brew.samples[0].id)
        #expect(saved.steps.map(\.kind) == [.pour(milliliters: 50), .pause, .action(.swirl), .pour(milliliters: 90), .pour(milliliters: 50)])
        #expect(saved.totalTime == 70)  // 10 + 20 + 5 + 20 + 15
        #expect(saved.rating == 6.5)
        #expect(saved.notes == "Flat.")
        #expect(router.saved.map(\.id) == [saved.id])
    }

    @Test func espressoEditsTheShot() async throws {
        let (viewModel, repository) = makeViewModel(Brew.samples[1])
        await viewModel.load()

        viewModel.shotTime = 31
        viewModel.actualYield = 40
        viewModel.brew.doseGrams = 20
        await viewModel.save()

        let saved = try await repository.fetch(id: Brew.samples[1].id)
        #expect(saved.espresso?.shotTime == 31)
        #expect(saved.espresso?.doseGrams == 20)
        #expect(saved.totalTime == 31)
        #expect(saved.ratio == 2)
    }

    @Test func missingBrewRoutesToNotFound() async {
        let (viewModel, _) = makeViewModel(Brew.samples[0], repository: TestRepository(brews: []))

        await viewModel.load()

        #expect(router.notFoundIDs == [Brew.samples[0].id])
    }

    @Test func deleteRemovesAndRoutesBack() async throws {
        let (viewModel, repository) = makeViewModel(Brew.samples[0])
        await viewModel.load()

        await viewModel.delete()

        #expect(try await repository.fetchAll().isEmpty)
        #expect(router.deletedIDs == [Brew.samples[0].id])
    }

    @Test func failedSaveShowsAlertAndStays() async {
        let (viewModel, _) = makeViewModel(Brew.samples[0], repository: TestRepository(brews: [Brew.samples[0]], failing: .writes))
        await viewModel.load()

        await viewModel.save()

        #expect(viewModel.alertMessage == "Boom")
        #expect(router.saved.isEmpty)
    }

    // MARK: - Logging (3.3)

    private func makeLogViewModel(brews: TestRepository<Brew> = TestRepository(brews: [])) -> BrewFormViewModel {
        Container.shared.brewRepository.register { brews }
        Container.shared.beanRepository.register { TestRepository(beans: Bean.samples) }
        Container.shared.deviceRepository.register { TestRepository(devices: Device.samples) }
        return BrewFormViewModel(mode: .add, router: router)
    }

    @Test func homeBrewWithYourBagIsLinkedToIt() async throws {
        let brews = TestRepository<Brew>(brews: [])
        let viewModel = makeLogViewModel(brews: brews)
        await viewModel.load()
        let grinder = try #require(Device.samples.first { $0.type == .grinder })

        viewModel.brew.method = .chemex
        viewModel.beanName = Bean.samples[0].name.uppercased()
        viewModel.grinderName = grinder.name
        viewModel.grindSetting = 22
        await viewModel.save()

        let logged = try #require(try await brews.fetchAll().first)
        #expect(logged.isManual)
        #expect(logged.method == .chemex)
        #expect(logged.bean?.beanID == Bean.samples[0].id)
        #expect(logged.grinder == GearReference(id: grinder.id, name: grinder.name))
        #expect(logged.grindSetting == 22)
        #expect((logged.doseGrams, logged.ratio, logged.beverageVolume) == (16, 16, 240))
        #expect(router.saved.map(\.id) == [logged.id])
    }

    @Test func cafeDrinkHasOnlyItsVolumeAndPlace() async throws {
        let brews = TestRepository<Brew>(brews: [])
        let viewModel = makeLogViewModel(brews: brews)
        await viewModel.load()

        viewModel.isCafe = true
        viewModel.cafePlace = " Blackwood "
        viewModel.beanName = Bean.samples[0].name
        viewModel.grinderName = "Comandante"
        await viewModel.save()

        let logged = try #require(try await brews.fetchAll().first)
        #expect(logged.origin == .cafe(place: "Blackwood"))
        #expect(logged.bean == BeanReference(name: Bean.samples[0].name))  // named, not from your stock
        #expect(logged.grinder == nil)
        #expect((logged.doseGrams, logged.ratio, logged.waterTemperature) == (0, 0, nil))
        viewModel.isCafe = false
        #expect(viewModel.brew.doseGrams == 16)
    }

    @Test func cancelRoutes() {
        let viewModel = makeLogViewModel()

        viewModel.cancel()

        #expect(router.cancelCount == 1)
    }
}
