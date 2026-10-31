import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import BrewsFeature

@Suite(.container)
@MainActor
struct NewBrewViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(repository: TestRepository<Brew> = TestRepository(brews: [])) -> NewBrewViewModel {
        Container.shared.brewRepository.register { repository }
        return NewBrewViewModel(router: router)
    }

    @Test func blankBeanNameIsInvalid() {
        let viewModel = makeViewModel()
        viewModel.beanName = "   "

        #expect(!viewModel.isValid)
    }

    @Test func saveStoresBrewAndFinishes() async {
        let repository = TestRepository(brews: [])
        let viewModel = makeViewModel(repository: repository)
        viewModel.beanName = "  Colombia Huila "
        viewModel.method = .chemex

        await viewModel.save()

        let saved = await repository.saved
        #expect(saved.count == 1)
        #expect(saved.first?.bean?.name == "Colombia Huila")
        #expect(saved.first?.method == .chemex)
        #expect(router.savedNewBrews == saved)
    }

    @Test func saveFailureKeepsScreenOpen() async {
        let viewModel = makeViewModel(repository: TestRepository(brews: [], failing: .everything))
        viewModel.beanName = "Kenya"

        await viewModel.save()

        #expect(viewModel.errorMessage == "Boom")
        #expect(router.savedNewBrews.isEmpty)
    }

    @Test func prefillsFromWizardSetupAndKeepsItsGear() async throws {
        let repository = TestRepository(brews: [])
        Container.shared.brewRepository.register { repository }
        var setup = BrewSetup(method: .chemex)
        setup.bean = BeanReference(beanID: .fixture(1), name: "Kenya")
        setup.dripper = GearReference(id: .fixture(2), name: "Chemex 6-cup")
        setup.waterTemperature = 94
        let viewModel = NewBrewViewModel(setup: setup, router: router)

        #expect(viewModel.method == .chemex)
        #expect(viewModel.beanName == "Kenya")
        #expect(viewModel.waterGrams == 256)

        await viewModel.save()

        let saved = try #require(await repository.saved.first)
        #expect(saved.bean?.beanID == .fixture(1))
        #expect(saved.dripper?.name == "Chemex 6-cup")
        #expect(saved.waterTemperature == 94)
    }
}
