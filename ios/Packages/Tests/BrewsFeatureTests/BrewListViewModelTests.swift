import FactoryKit
import FactoryTesting
import Testing
import Domain
@testable import BrewsFeature

/// `.container` gives every test its own Factory container, so registrations don't leak
/// between tests and the suite can run in parallel.
@Suite(.container)
@MainActor
struct BrewListViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(repository: MockBrewRepository) -> BrewListViewModel {
        Container.shared.brewRepository.register { repository }
        return BrewListViewModel(router: router)
    }

    @Test func loadPublishesBrews() async {
        let viewModel = makeViewModel(repository: MockBrewRepository(brews: Brew.samples))

        await viewModel.load()

        #expect(viewModel.state == .loaded(Brew.samples))
    }

    @Test func loadWithNoBrewsIsEmpty() async {
        let viewModel = makeViewModel(repository: MockBrewRepository())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func loadFailureShowsError() async {
        let viewModel = makeViewModel(repository: MockBrewRepository(error: TestError()))

        await viewModel.load()

        #expect(viewModel.state == .failed("Boom"))
    }

    @Test func selectingBrewRoutesToDetail() {
        let viewModel = makeViewModel(repository: MockBrewRepository())

        viewModel.didSelect(Brew.samples[1])

        #expect(router.shownDetailIDs == [Brew.samples[1].id])
    }

    @Test func tappingAddRoutesToNewBrew() {
        let viewModel = makeViewModel(repository: MockBrewRepository())

        viewModel.didTapAdd()

        #expect(router.newBrewShownCount == 1)
    }

    @Test func usesPreviewDataWhenNothingIsRegistered() async {
        // Default registration = fixtures; this is what SwiftUI previews get.
        let viewModel = BrewListViewModel(router: router)

        await viewModel.load()

        #expect(viewModel.state == .loaded(Brew.samples))
    }
}
