import Foundation
import FactoryKit
import FactoryTesting
import Testing
import Domain
import TestSupport
@testable import JournalFeature

/// `.container` gives every test its own Factory container, so registrations don't leak
/// between tests and the suite can run in parallel.
@Suite(.container)
@MainActor
struct FeedViewModelTests {
    private let router = SpyRouter()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Kyiv")!
        return calendar
    }

    private func makeViewModel(repository: TestRepository<Brew>) -> FeedViewModel {
        Container.shared.brewRepository.register { repository }
        return FeedViewModel(router: router, calendar: calendar)
    }

    private func brew(_ day: Int, _ hour: Int) -> Brew {
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
        return Brew(date: date, method: .v60, doseGrams: 16, ratio: 16, rating: 8)
    }

    @Test func brewsAreGroupedByDayNewestFirst() async {
        let brews = [brew(31, 23), brew(31, 8), brew(30, 0), brew(28, 12)]
        let viewModel = makeViewModel(repository: TestRepository(brews: brews))

        await viewModel.load()

        guard case .loaded(let days) = viewModel.state else { Issue.record("Not loaded"); return }
        #expect(days.map(\.brews) == [[brews[0], brews[1]], [brews[2]], [brews[3]]])
        #expect(days.map { calendar.component(.day, from: $0.date) } == [31, 30, 28])
    }

    @Test func emptyAndFailedStates() async {
        let empty = makeViewModel(repository: TestRepository(brews: []))
        await empty.load()
        #expect(empty.state == .empty)

        let failing = makeViewModel(repository: TestRepository(brews: [], failing: .everything))
        await failing.load()
        #expect(failing.state == .failed("Boom"))
    }

    @Test func likeIsSavedAndToggledBack() async throws {
        let repository = TestRepository(brews: [Brew.samples[0]])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.toggleLike(Brew.samples[0])
        let liked = try await repository.fetch(id: Brew.samples[0].id)
        #expect(liked.isLiked)
        await viewModel.toggleLike(liked)
        #expect(try await repository.fetch(id: liked.id).isLiked == false)
    }

    @Test func routes() {
        let viewModel = makeViewModel(repository: TestRepository(brews: []))

        viewModel.didSelect(Brew.samples[1])
        viewModel.didTapAdd()
        viewModel.didTapLog()

        #expect(router.shownIDs == [Brew.samples[1].id])
        #expect(router.newBrewShownCount == 1)
        #expect(router.logShownCount == 1)
    }

    @Test func pickingBrewsToCompare() async {
        let brews = (1...5).map { brew(31, $0) }
        let viewModel = makeViewModel(repository: TestRepository(brews: brews))
        await viewModel.load()

        viewModel.toggleCompare(brews[0])
        #expect(viewModel.showsCompareBar && !viewModel.canCompare)   // one: the bar, disabled
        viewModel.didTapCompare()                       // no route yet
        #expect(router.compared.isEmpty)
        brews.dropFirst().forEach(viewModel.toggleCompare)   // the fifth is one too many
        #expect(viewModel.compared == brews.prefix(4).map(\.id))
        #expect(viewModel.alertMessage != nil)
        viewModel.toggleCompare(brews[1])               // unpick
        viewModel.didTapCompare()
        #expect(router.compared == [[brews[0].id, brews[2].id, brews[3].id]])

        viewModel.resetCompare()
        #expect(viewModel.compared.isEmpty)
    }

    @Test func filteringNarrowsTheDaysAndKeepsPicks() async {
        var latte = brew(30, 9)
        latte.method = .latte
        latte.isLiked = true
        let brews = [brew(31, 9), latte]
        let viewModel = makeViewModel(repository: TestRepository(brews: brews))
        await viewModel.load()
        #expect(viewModel.methods == [.v60, .latte])   // most recent first
        viewModel.toggleCompare(brews[0])

        viewModel.filter.isLikedOnly = true
        #expect(viewModel.state == .loaded([FeedViewModel.Day(date: calendar.startOfDay(for: latte.date), brews: [latte])]))
        #expect(viewModel.compared == [brews[0].id])   // hidden, still picked

        viewModel.filter.methods = [.v60]
        #expect(viewModel.state == .empty)             // "No brews match"
        viewModel.filter.clear()
        guard case .loaded(let days) = viewModel.state else { Issue.record("Not loaded"); return }
        #expect(days.flatMap(\.brews) == brews)
    }

    @Test func theFilterSheetEditsTheFeedsFilters() {
        let viewModel = makeViewModel(repository: TestRepository(brews: []))
        var changes: [Bool] = []
        viewModel.onHasFiltersChange = { changes.append($0) }

        viewModel.didTapFilters()
        #expect(router.shownFilters.first?.feed === viewModel)
        viewModel.filter.isLikedOnly = true
        viewModel.filter.methods = [.v60]   // still on: no second call
        viewModel.filter.text = "guji"
        viewModel.filter.clear()
        #expect(changes == [true, false])   // fills, then empties the filter button
    }

    @Test func aMethodGoneFromTheJournalLeavesTheFilter() async throws {
        let only = brew(31, 9)
        let repository = TestRepository(brews: [only])
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()
        viewModel.filter.methods = [.v60]

        try await repository.delete(id: only.id)
        await viewModel.load()

        #expect(viewModel.methods.isEmpty && viewModel.filter.methods.isEmpty)
    }

    @Test func aDeletedBrewDropsOutOfTheComparison() async {
        let repository = TestRepository(brews: Brew.samples)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()
        viewModel.toggleCompare(Brew.samples[0])
        viewModel.toggleCompare(Brew.samples[1])

        try? await repository.delete(id: Brew.samples[0].id)
        await viewModel.load()

        #expect(viewModel.compared == [Brew.samples[1].id])
    }
}
