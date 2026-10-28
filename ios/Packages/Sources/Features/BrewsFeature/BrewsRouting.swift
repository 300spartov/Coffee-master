import Domain

// Navigation intents emitted by the feature's view models.
// The feature doesn't know *how* navigation happens; a Flow in the app target implements these.

@MainActor
public protocol BrewListRouting: AnyObject {
    func showBrewDetail(id: Brew.ID)
    func showNewBrew()
}

@MainActor
public protocol BrewDetailRouting: AnyObject {
    func brewDetailDidDelete(id: Brew.ID)
}

@MainActor
public protocol NewBrewRouting: AnyObject {
    /// `brew` is `nil` when the user cancelled.
    func newBrewDidFinish(saved brew: Brew?)
}
