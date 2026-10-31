import Domain

// Navigation intents emitted by the brew wizard's view models.
// The feature doesn't know *how* navigation happens; `BrewFlow` in the app target implements these.
public protocol MethodPickRouting: AnyObject {
    /// Step 1 → 2: the methods of the chosen group.
    func showMethods(in group: MethodGroup)
    /// A method was picked; the wizard continues with setup.
    func methodPickDidSelect(_ method: BrewMethod)
    /// Cancel on step 1 closes the wizard.
    func methodPickDidCancel()
}
