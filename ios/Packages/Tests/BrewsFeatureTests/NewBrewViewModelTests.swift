import Testing
import Domain
@testable import BrewsFeature

@MainActor
struct NewBrewViewModelTests {
    private let router = SpyRouter()

    @Test func blankBeanNameIsInvalid() {
        let viewModel = NewBrewViewModel(repository: MockBrewRepository(), router: router)
        viewModel.beanName = "   "

        #expect(!viewModel.isValid)
    }

    @Test func saveStoresBrewAndFinishes() async {
        let repository = MockBrewRepository()
        let viewModel = NewBrewViewModel(repository: repository, router: router)
        viewModel.beanName = "  Colombia Huila "
        viewModel.method = .chemex

        await viewModel.save()

        let saved = await repository.savedBrews
        #expect(saved.count == 1)
        #expect(saved.first?.beanName == "Colombia Huila")
        #expect(saved.first?.method == .chemex)
        #expect(router.finishedNewBrews == [saved.first])
    }

    @Test func saveFailureKeepsScreenOpen() async {
        let viewModel = NewBrewViewModel(repository: MockBrewRepository(error: TestError()), router: router)
        viewModel.beanName = "Kenya"

        await viewModel.save()

        #expect(viewModel.errorMessage == "Boom")
        #expect(router.finishedNewBrews.isEmpty)
    }

    @Test func cancelFinishesWithoutBrew() {
        let viewModel = NewBrewViewModel(repository: MockBrewRepository(), router: router)

        viewModel.cancel()

        #expect(router.finishedNewBrews == [nil])
    }
}
