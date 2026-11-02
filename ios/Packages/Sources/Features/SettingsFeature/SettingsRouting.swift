public protocol SettingsRouting: AnyObject {
    func showAbout()
    /// Pick a web app JSON export and import it.
    func showWebImport()
    /// Debug builds only: component gallery.
    func showDesignSystem()
}
