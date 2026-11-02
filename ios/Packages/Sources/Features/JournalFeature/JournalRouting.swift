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
}

public protocol BrewFormRouting: AnyObject {
    /// Saved (edited or logged): back to the feed.
    func brewFormDidSave(_ brew: Brew)
    /// Logging was cancelled.
    func brewFormDidCancel()
    func brewFormDidDelete(id: Brew.ID)
    /// The brew doesn't exist (anymore), e.g. a stale deep link.
    func brewFormNotFound(id: Brew.ID)
}
