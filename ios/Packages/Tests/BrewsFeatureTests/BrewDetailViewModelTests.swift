import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import BrewsFeature

@Suite(.container)
@MainActor
struct BrewDetailViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(id: Brew.ID, repository: TestRepository<Brew>) -> BrewDetailViewModel {
        Container.shared.brewRepository.register { repository }
        return BrewDetailViewModel(brewID: id, router: router)
    }

    @Test func loadsBrew() async {
        let brew = Brew.samples[0]
        let viewModel = makeViewModel(id: brew.id, repository: TestRepository(brews: [brew]))

        await viewModel.load()

        #expect(viewModel.state == .loaded(brew))
    }

    @Test func missingBrewRoutesToNotFound() async {
        let viewModel = makeViewModel(id: Brew.samples[0].id, repository: TestRepository(brews: []))

        await viewModel.load()

        #expect(router.notFoundIDs == [Brew.samples[0].id])
    }

    @Test func deleteRemovesAndRoutesBack() async throws {
        let brew = Brew.samples[0]
        let repository = TestRepository(brews: [brew])
        let viewModel = makeViewModel(id: brew.id, repository: repository)
        await viewModel.load()

        await viewModel.delete()

        #expect(try await repository.fetchAll().isEmpty)
        #expect(router.deletedIDs == [brew.id])
    }

    @Test func failedDeleteShowsAlertAndStays() async {
        let viewModel = makeViewModel(id: Brew.samples[0].id, repository: TestRepository(brews: [], failing: .everything))

        await viewModel.delete()

        #expect(viewModel.alertMessage == "Boom")
        #expect(router.deletedIDs.isEmpty)
    }
}
