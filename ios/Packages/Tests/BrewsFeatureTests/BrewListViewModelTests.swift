import Testing
import Domain
@testable import BrewsFeature

@MainActor
struct BrewListViewModelTests {
    private let router = SpyRouter()

    @Test func loadPublishesBrews() async {
        let viewModel = BrewListViewModel(repository: MockBrewRepository(brews: Brew.samples), router: router)

        await viewModel.load()

        #expect(viewModel.state == .loaded(Brew.samples))
    }

    @Test func loadWithNoBrewsIsEmpty() async {
        let viewModel = BrewListViewModel(repository: MockBrewRepository(), router: router)

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func loadFailureShowsError() async {
        let viewModel = BrewListViewModel(repository: MockBrewRepository(error: TestError()), router: router)

        await viewModel.load()

        #expect(viewModel.state == .failed("Boom"))
    }

    @Test func selectingBrewRoutesToDetail() {
        let viewModel = BrewListViewModel(repository: MockBrewRepository(), router: router)

        viewModel.didSelect(Brew.samples[1])

        #expect(router.shownDetailIDs == [Brew.samples[1].id])
    }

    @Test func tappingAddRoutesToNewBrew() {
        let viewModel = BrewListViewModel(repository: MockBrewRepository(), router: router)

        viewModel.didTapAdd()

        #expect(router.newBrewShownCount == 1)
    }
}
