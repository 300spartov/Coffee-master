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
        #expect(router.finishedNewBrews == [saved.first])
    }

    @Test func saveFailureKeepsScreenOpen() async {
        let viewModel = makeViewModel(repository: TestRepository(brews: [], failing: .everything))
        viewModel.beanName = "Kenya"

        await viewModel.save()

        #expect(viewModel.errorMessage == "Boom")
        #expect(router.finishedNewBrews.isEmpty)
    }

    @Test func cancelFinishesWithoutBrew() {
        let viewModel = makeViewModel()

        viewModel.cancel()

        #expect(router.finishedNewBrews == [nil])
    }
}
