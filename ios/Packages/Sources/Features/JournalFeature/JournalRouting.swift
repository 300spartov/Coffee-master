import Domain

// Navigation intents emitted by the feature's view models.
// The feature doesn't know *how* navigation happens; a Flow in the app target implements these.
public protocol FeedRouting: AnyObject {
    /// A card was tapped: open the brew to edit it.
    func showBrew(id: Brew.ID)
    /// Start a brew (the wizard).
    func showNewBrew()
    /// Log a brew after the fact.
    func showLogBrew()
    /// Compare the picked brews (2–4, in the order they were picked).
    func showCompare(brewIDs: [Brew.ID])
}

public protocol BrewFormRouting: AnyObject {
    /// Logged (`added`), edited (`updated`), deleted, logging cancelled, or the brew is gone (e.g. a
    /// stale deep link).
    func brewForm(didFinish result: FormResult<Brew>)
}
