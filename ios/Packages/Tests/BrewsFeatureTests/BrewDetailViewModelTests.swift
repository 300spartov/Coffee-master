import FactoryKit
import FactoryTesting
import Testing
import Domain
@testable import BrewsFeature

@Suite(.container)
@MainActor
struct BrewDetailViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(id: Brew.ID, repository: MockBrewRepository) -> BrewDetailViewModel {
        Container.shared.brewRepository.register { repository }
        return BrewDetailViewModel(brewID: id, router: router)
    }

    @Test func loadsBrew() async {
        let brew = Brew.samples[0]
        let viewModel = makeViewModel(id: brew.id, repository: MockBrewRepository(brews: [brew]))

        await viewModel.load()

        #expect(viewModel.state == .loaded(brew))
    }

    @Test func missingBrewRoutesToNotFound() async {
        let viewModel = makeViewModel(id: Brew.samples[0].id, repository: MockBrewRepository())

        await viewModel.load()

        #expect(router.notFoundIDs == [Brew.samples[0].id])
    }

    @Test func deleteRemovesAndRoutesBack() async {
        let brew = Brew.samples[0]
        let repository = MockBrewRepository(brews: [brew])
        let viewModel = makeViewModel(id: brew.id, repository: repository)
        await viewModel.load()

        await viewModel.delete()

        #expect(await repository.brews.isEmpty)
        #expect(router.deletedIDs == [brew.id])
    }

    @Test func failedDeleteShowsAlertAndStays() async {
        let viewModel = makeViewModel(id: Brew.samples[0].id, repository: MockBrewRepository(error: TestError()))

        await viewModel.delete()

        #expect(viewModel.alertMessage == "Boom")
        #expect(router.deletedIDs.isEmpty)
    }
}
