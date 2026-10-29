import FactoryKit
import FactoryTesting
import Testing
import Domain
@testable import BeansFeature

@Suite(.container)
@MainActor
struct BeanFormViewModelTests {
    private let router = SpyRouter()
    private let suggestions = InMemorySuggestionsRepository(Suggestions(roasters: ["Penyora"], beanNames: ["Kenya AA"]))

    private func makeViewModel(_ mode: BeanFormViewModel.Mode, repository: MockBeanRepository) -> BeanFormViewModel {
        Container.shared.beanRepository.register { repository }
        Container.shared.suggestionsRepository.register { [suggestions] in suggestions }
        return BeanFormViewModel(mode: mode, router: router)
    }

    // MARK: - Add

    @Test func addCreatesFullBagAndRemembersSuggestions() async throws {
        let repository = MockBeanRepository()
        let viewModel = makeViewModel(.add, repository: repository)
        await viewModel.load()
        viewModel.name = "  Ethiopia Guji "
        viewModel.roaster = "Wonder&Full"
        viewModel.totalGrams = 500
        viewModel.process = .natural
        viewModel.score = 88.5

        await viewModel.save()

        let saved = try #require(await repository.savedBeans.first)
        #expect(saved.name == "Ethiopia Guji")
        #expect(saved.totalGrams == 500)
        #expect(saved.remainingGrams == 500)
        #expect(saved.process == .natural)
        #expect(saved.score == 88.5)
        #expect(router.finished == [saved])
        let remembered = try await suggestions.suggestions()
        #expect(remembered.roasters == ["Penyora", "Wonder&Full"])
        #expect(remembered.beanNames == ["Kenya AA", "Ethiopia Guji"])
    }

    @Test func validation() async {
        let viewModel = makeViewModel(.add, repository: MockBeanRepository())

        #expect(!viewModel.isValid) // no name
        viewModel.name = "Kenya"
        #expect(viewModel.isValid)
        viewModel.score = 120
        #expect(!viewModel.isScoreValid)
        #expect(!viewModel.isValid)
        viewModel.score = nil
        viewModel.totalGrams = 0
        #expect(!viewModel.isValid)
    }

    @Test func invalidFormDoesNotSave() async {
        let repository = MockBeanRepository()
        let viewModel = makeViewModel(.add, repository: repository)

        await viewModel.save()

        #expect(await repository.savedBeans.isEmpty)
        #expect(router.finished.isEmpty)
    }

    @Test func cancelFinishesWithoutBean() {
        let viewModel = makeViewModel(.add, repository: MockBeanRepository())

        viewModel.cancel()

        #expect(router.finished == [nil])
    }

    @Test func suggestionsCombineRememberedAndExistingBeans() async {
        let viewModel = makeViewModel(.add, repository: MockBeanRepository(beans: Bean.samples))

        await viewModel.load()

        #expect(viewModel.roasterSuggestions.contains("Penyora"))
        #expect(viewModel.roasterSuggestions.contains("Wonder&Full"))
        #expect(viewModel.nameSuggestions.contains("Brazil Cerrado"))
    }

    // MARK: - Edit

    @Test func editLoadsFieldsAndKeepsUsedAmountOnResize() async throws {
        let bean = Bean(id: .fixture(9), name: "Kenya", roaster: "Penyora", totalGrams: 250, remainingGrams: 100, score: 86)
        let repository = MockBeanRepository(beans: [bean])
        let viewModel = makeViewModel(.edit(bean.id), repository: repository)

        await viewModel.load()
        #expect(viewModel.state == .ready)
        #expect(viewModel.name == "Kenya")
        #expect(viewModel.remainingGrams == 100)
        #expect(viewModel.score == 86)

        viewModel.totalGrams = 1_000
        viewModel.descriptors = "Blackcurrant"
        await viewModel.save()

        let saved = try #require(await repository.savedBeans.last)
        #expect(saved.id == bean.id)
        #expect(saved.totalGrams == 1_000)
        #expect(saved.remainingGrams == 850) // 150 g already used
        #expect(saved.descriptors == "Blackcurrant")
    }

    @Test func missingBeanRoutesToNotFound() async {
        let viewModel = makeViewModel(.edit(.fixture(404)), repository: MockBeanRepository())

        await viewModel.load()

        #expect(router.notFoundIDs == [.fixture(404)])
    }

    @Test func deleteRoutesBack() async {
        let bean = Bean.samples[0]
        let repository = MockBeanRepository(beans: [bean])
        let viewModel = makeViewModel(.edit(bean.id), repository: repository)
        await viewModel.load()

        await viewModel.delete()

        #expect(await repository.beans.isEmpty)
        #expect(router.deletedIDs == [bean.id])
    }

    @Test func failedSaveShowsAlert() async {
        let viewModel = makeViewModel(.add, repository: MockBeanRepository(error: TestError()))
        viewModel.name = "Kenya"

        await viewModel.save()

        #expect(viewModel.alertMessage == "Boom")
        #expect(router.finished.isEmpty)
    }
}
