import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// The Journal feed (web: `renderFeed`): brews newest first, grouped by day, with like and delete.
@Observable
final class FeedViewModel: AlertingViewModel {
    /// The brews of one calendar day, newest first.
    nonisolated struct Day: Identifiable, Equatable, Sendable {
        /// The day's start.
        let date: Date
        var brews: [Brew]

        var id: Date { date }
    }

    private(set) var state: ListState<Day> = .loading
    /// Brews picked for the comparison, in the order they were picked (up to `Brew.maximumCompared`).
    private(set) var compared: [Brew.ID] = [] {
        didSet {
            if showsCompareBar != !oldValue.isEmpty { onShowsCompareBarChange?(showsCompareBar) }
        }
    }
    /// Called when the compare bar appears or goes (the module puts it in the tab bar on iOS 26).
    @ObservationIgnored var onShowsCompareBarChange: ((Bool) -> Void)?
    /// A failed action (like, delete), shown as an alert over the feed (`attempt`).
    var alertMessage: String?

    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored @Injected(\.brewRepository) private var repository
    @ObservationIgnored private weak var router: (any FeedRouting)?

    init(router: any FeedRouting, calendar: Calendar = .current) {
        self.router = router
        self.calendar = calendar
    }

    /// Bound to the view's lifetime via `.task`: loads, then reloads on every repository change.
    func start() async {
        await repository.observe { await self.load() }
    }

    func load() async {
        do {
            let brews = try await repository.fetchAll()
            state = ListState(Self.days(of: brews, calendar: calendar))
            // A picked brew that was deleted drops out of the comparison.
            compared = compared.filter { id in brews.contains { $0.id == id } }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Groups brews (already newest first) by calendar day, keeping their order.
    static func days(of brews: [Brew], calendar: Calendar) -> [Day] {
        brews.reduce(into: []) { days, brew in
            let day = calendar.startOfDay(for: brew.date)
            if days.last?.date == day {
                days[days.count - 1].brews.append(brew)
            } else {
                days.append(Day(date: day, brews: [brew]))
            }
        }
    }

    func didSelect(_ brew: Brew) {
        router?.showBrew(id: brew.id)
    }

    func didTapAdd() {
        router?.showNewBrew()
    }

    func didTapLog() {
        router?.showLogBrew()
    }

    // MARK: - Compare

    /// From the first picked brew on (so you see the pick and can reset it).
    var showsCompareBar: Bool { !compared.isEmpty }

    /// Comparing needs two brews; until then the bar's button is disabled.
    var canCompare: Bool { compared.count >= 2 }

    func toggleCompare(_ brew: Brew) {
        if let index = compared.firstIndex(of: brew.id) {
            compared.remove(at: index)
        } else if compared.count < Brew.maximumCompared {
            compared.append(brew.id)
        } else {
            alertMessage = tr("You can compare up to \(Brew.maximumCompared) brews.")
        }
    }

    func resetCompare() {
        compared = []
    }

    func didTapCompare() {
        guard canCompare else { return }
        router?.showCompare(brewIDs: compared)
    }

    func toggleLike(_ brew: Brew) async {
        var liked = brew
        liked.isLiked.toggle()
        await attempt { try await self.repository.save(liked) }
    }

    /// Moves the brew to the trash, with Undo (`trashBrew`).
    func delete(_ brew: Brew) async {
        await attempt { try await trashBrew(id: brew.id) }
    }
}
