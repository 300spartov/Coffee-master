import FactoryKit
import FactoryTesting
import Testing
import Domain
@testable import BeansFeature

/// `.container` gives every test its own Factory container, so registrations don't leak
/// between tests and the suite can run in parallel.
@Suite(.container)
@MainActor
struct BeanListViewModelTests {
    private let router = SpyRouter()

    private func makeViewModel(repository: MockBeanRepository) -> BeanListViewModel {
        Container.shared.beanRepository.register { repository }
        return BeanListViewModel(router: router)
    }

    @Test func loadPublishesBeans() async {
        let viewModel = makeViewModel(repository: MockBeanRepository(beans: Bean.samples))

        await viewModel.load()

        #expect(viewModel.state == .loaded(Bean.samples))
    }

    @Test func loadWithNoBeansIsEmpty() async {
        let viewModel = makeViewModel(repository: MockBeanRepository())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func loadFailureShowsError() async {
        let viewModel = makeViewModel(repository: MockBeanRepository(error: TestError()))

        await viewModel.load()

        #expect(viewModel.state == .failed("Boom"))
    }

    @Test func selectingBeanRoutesToDetail() {
        let viewModel = makeViewModel(repository: MockBeanRepository())

        viewModel.didSelect(Bean.samples[0])

        #expect(router.shownDetailIDs == [Bean.samples[0].id])
    }

    @Test func tappingAddRoutesToAddBean() {
        let viewModel = makeViewModel(repository: MockBeanRepository())

        viewModel.didTapAdd()

        #expect(router.addBeanShownCount == 1)
    }

    @Test func usesPreviewDataWhenNothingIsRegistered() async {
        // Default registration = fixtures; this is what SwiftUI previews get.
        let viewModel = BeanListViewModel(router: router)

        await viewModel.load()

        guard case .loaded(let beans) = viewModel.state else {
            Issue.record("Expected .loaded state")
            return
        }
        #expect(Set(beans.map(\.id)) == Set(Bean.samples.map(\.id)))
    }
}

@Suite(.container)
@MainActor
struct BeanListDeleteTests {
    @Test func failedDeleteKeepsListAndShowsAlert() async {
        Container.shared.beanRepository.register { MockBeanRepository(beans: Bean.samples, deleteError: TestError()) }
        let viewModel = BeanListViewModel(router: SpyRouter())
        await viewModel.load()

        await viewModel.delete([Bean.samples[0]])

        #expect(viewModel.state == .loaded(Bean.samples))
        #expect(viewModel.alertMessage == "Boom")
    }

    @Test func successfulDeleteDeletesFromRepository() async {
        let repository = MockBeanRepository(beans: Bean.samples)
        Container.shared.beanRepository.register { repository }
        let viewModel = BeanListViewModel(router: SpyRouter())
        await viewModel.load()

        await viewModel.delete([Bean.samples[0]])

        let remaining = try? await repository.fetchAll()
        #expect(remaining?.count == Bean.samples.count - 1)
        #expect(remaining?.first?.id == Bean.samples[1].id)
    }
}
