import Foundation
import Domain
@testable import BrewsFeature

@MainActor
final class SpyRouter: BrewListRouting, BrewDetailRouting, NewBrewRouting {
    private(set) var shownDetailIDs: [Brew.ID] = []
    private(set) var newBrewShownCount = 0
    private(set) var deletedIDs: [Brew.ID] = []
    private(set) var notFoundIDs: [Brew.ID] = []
    private(set) var finishedNewBrews: [Brew?] = []

    func showBrewDetail(id: Brew.ID) { shownDetailIDs.append(id) }
    func showNewBrew() { newBrewShownCount += 1 }
    func brewDetailDidDelete(id: Brew.ID) { deletedIDs.append(id) }
    func brewDetailNotFound(id: Brew.ID) { notFoundIDs.append(id) }
    func newBrewDidFinish(saved brew: Brew?) { finishedNewBrews.append(brew) }
}
