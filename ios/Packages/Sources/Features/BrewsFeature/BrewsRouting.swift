import Domain

// Navigation intents emitted by the feature's view models.
// The feature doesn't know *how* navigation happens; a Flow in the app target implements these.
public protocol BrewListRouting: AnyObject {
    func showBrewDetail(id: Brew.ID)
    func showNewBrew()
}
public protocol BrewDetailRouting: AnyObject {
    func brewDetailDidDelete(id: Brew.ID)
    /// The brew doesn't exist (anymore), e.g. a stale deep link.
    func brewDetailNotFound(id: Brew.ID)
}
public protocol NewBrewRouting: AnyObject {
    /// `brew` is `nil` when the user cancelled.
    func newBrewDidFinish(saved brew: Brew?)
}
