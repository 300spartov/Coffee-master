#if DEBUG
import Domain

/// No-op router for SwiftUI previews. Retained by `shared` because view models hold routers weakly.
final class PreviewRouter: FeedRouting, BrewFormRouting {
    static let shared = PreviewRouter()

    func showBrew(id: Brew.ID) {}
    func showNewBrew() {}
    func showLogBrew() {}
    func showCompare(brewIDs: [Brew.ID]) {}
    func brewForm(didFinish result: FormResult<Brew>) {}
}
#endif
