#if DEBUG
import Domain

/// No-op router for SwiftUI previews. Retained by `shared` because view models hold routers weakly.
final class PreviewRouter: FeedRouting, BrewFormRouting {
    static let shared = PreviewRouter()

    func showBrew(id: Brew.ID) {}
    func showNewBrew() {}
    func showLogBrew() {}
    func brewFormDidCancel() {}
    func brewFormDidSave(_ brew: Brew) {}
    func brewFormDidDelete(id: Brew.ID) {}
    func brewFormNotFound(id: Brew.ID) {}
}
#endif
