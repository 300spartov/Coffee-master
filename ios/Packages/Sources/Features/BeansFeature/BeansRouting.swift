import Domain

// Navigation intents emitted by the feature's view models.
// The feature doesn't know *how* navigation happens; a Flow in the app target implements these.
public protocol BeanListRouting: AnyObject {
    func showBeanDetail(id: Bean.ID)
    func showAddBean()
}

public protocol BeanFormRouting: AnyObject {
    /// Added, updated, deleted, cancelled, or the bean is gone (e.g. a stale deep link).
    func beanForm(didFinish result: FormResult<Bean>)
}
