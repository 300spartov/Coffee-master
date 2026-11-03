import Foundation
import Domain
@testable import JournalFeature

@MainActor
final class SpyRouter: FeedRouting, BrewFormRouting {
    private(set) var shownIDs: [Brew.ID] = []
    private(set) var newBrewShownCount = 0
    private(set) var logShownCount = 0
    private(set) var compared: [[Brew.ID]] = []
    private(set) var shownFilters: [FeedFilters] = []
    private(set) var cancelCount = 0
    private(set) var saved: [Brew] = []
    private(set) var deletedIDs: [Brew.ID] = []
    private(set) var notFoundCount = 0

    func showBrew(id: Brew.ID) { shownIDs.append(id) }
    func showNewBrew() { newBrewShownCount += 1 }
    func showLogBrew() { logShownCount += 1 }
    func showCompare(brewIDs: [Brew.ID]) { compared.append(brewIDs) }
    func showFilters(_ filters: FeedFilters) { shownFilters.append(filters) }
    func brewForm(didFinish result: FormResult<Brew>) {
        switch result {
        case .added(let brew), .updated(let brew): saved.append(brew)
        case .cancelled: cancelCount += 1
        case .deleted(let id): deletedIDs.append(id)
        case .notFound: notFoundCount += 1
        }
    }
}
