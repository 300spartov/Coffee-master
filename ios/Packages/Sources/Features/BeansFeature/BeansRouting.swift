import Domain

// Navigation intents emitted by the feature's view models.
// The feature doesn't know *how* navigation happens; a Flow in the app target implements these.
public protocol BeanListRouting: AnyObject {
    func showBeanDetail(id: Bean.ID)
    func showAddBean()
}

public protocol BeanFormRouting: AnyObject {
    /// `bean` is `nil` when the user cancelled (add) without saving.
    func beanFormDidFinish(saved bean: Bean?)
    func beanFormDidDelete(id: Bean.ID)
    /// The bean being edited doesn't exist (anymore), e.g. a stale deep link.
    func beanFormNotFound(id: Bean.ID)
}
