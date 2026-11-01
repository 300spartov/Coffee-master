import Foundation
import Domain
@testable import JournalFeature

@MainActor
final class SpyRouter: FeedRouting, BrewFormRouting {
    private(set) var shownIDs: [Brew.ID] = []
    private(set) var newBrewShownCount = 0
    private(set) var saved: [Brew] = []
    private(set) var deletedIDs: [Brew.ID] = []
    private(set) var notFoundIDs: [Brew.ID] = []

    func showBrew(id: Brew.ID) { shownIDs.append(id) }
    func showNewBrew() { newBrewShownCount += 1 }
    func brewFormDidSave(_ brew: Brew) { saved.append(brew) }
    func brewFormDidDelete(id: Brew.ID) { deletedIDs.append(id) }
    func brewFormNotFound(id: Brew.ID) { notFoundIDs.append(id) }
}
