#if DEBUG
import Domain

/// No-op router for SwiftUI previews. Retained by `shared` because view models hold routers weakly.
final class PreviewRouter: BrewListRouting, BrewDetailRouting {
    static let shared = PreviewRouter()

    func showBrewDetail(id: Brew.ID) {}
    func showNewBrew() {}
    func brewDetailDidDelete(id: Brew.ID) {}
    func brewDetailNotFound(id: Brew.ID) {}
}
#endif
