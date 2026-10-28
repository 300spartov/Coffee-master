@MainActor
public protocol SettingsRouting: AnyObject {
    func showAbout()
    /// Cross-feature intent: the flow decides how to reach the Brews feature (via a deep link).
    func showNewBrew()
}
