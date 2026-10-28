import Factory
import FactoryTesting
import Testing
import Domain
@testable import BrewsFeature

@Suite(.container)
@MainActor
struct NewBrewViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(repository: MockBrewRepository = MockBrewRepository()) -> NewBrewViewModel {
        Container.shared.brewRepository.register { repository }
        return NewBrewViewModel(router: router)
    }

    @Test func blankBeanNameIsInvalid() {
        let viewModel = makeViewModel()
        viewModel.beanName = "   "

        #expect(!viewModel.isValid)
    }

    @Test func saveStoresBrewAndFinishes() async {
        let repository = MockBrewRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.beanName = "  Colombia Huila "
        viewModel.method = .chemex

        await viewModel.save()

        let saved = await repository.savedBrews
        #expect(saved.count == 1)
        #expect(saved.first?.bean?.name == "Colombia Huila")
        #expect(saved.first?.method == .chemex)
        #expect(router.finishedNewBrews == [saved.first])
    }

    @Test func saveFailureKeepsScreenOpen() async {
        let viewModel = makeViewModel(repository: MockBrewRepository(error: TestError()))
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
