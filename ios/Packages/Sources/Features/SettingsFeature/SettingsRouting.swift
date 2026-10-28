@MainActor
public protocol SettingsRouting: AnyObject {
    func showAbout()
    /// Cross-feature intent: the flow decides how to reach the Brews feature (via a deep link).
    func showNewBrew()
    /// Pick a web app JSON export and import it.
    func showWebImport()
}
