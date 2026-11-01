import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// The Journal feed (web: `renderFeed`): brews newest first, grouped by day, with like and delete.
@Observable
final class FeedViewModel {
    /// The brews of one calendar day, newest first.
    nonisolated struct Day: Identifiable, Equatable, Sendable {
        /// The day's start.
        let date: Date
        var brews: [Brew]

        var id: Date { date }
    }

    private(set) var state: ListState<Day> = .loading
    /// A failed action (like, delete), shown as an alert over the feed.
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
            state = ListState(Self.days(of: try await repository.fetchAll(), calendar: calendar))
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
        router?.showBrewDetail(id: brew.id)
    }

    func didTapAdd() {
        router?.showNewBrew()
    }

    func toggleLike(_ brew: Brew) async {
        var liked = brew
        liked.isLiked.toggle()
        await perform { try await self.repository.save(liked) }
    }

    /// Moves the brew to the trash (its coffee and filter go back to stock).
    func delete(_ brew: Brew) async {
        await perform { try await self.repository.delete(id: brew.id) }
    }

    /// The change stream reloads the feed after a write; a failure keeps it as it is.
    private func perform(_ write: () async throws -> Void) async {
        do {
            try await write()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
