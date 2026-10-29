import UIKit
import FactoryKit
import AppCore
import Domain

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Process-wide setup: analytics, crash reporting, push registration.
        // Colors and bar appearance: `ThemeAppearance` (applied per window in `AppRouter`).
        // Dependencies: Factory registrations in `DI/Container+App.swift`.
        purgeExpiredTrash()
        return true
    }

    /// Deleted brews stay in the trash for `TrashPolicy.retention` (30 days), like the web app.
    private func purgeExpiredTrash() {
        let trash = Container.shared.trashRepository()
        Task.detached(priority: .utility) {
            do {
                let purged = try await trash.purgeExpired(now: .now)
                if purged > 0 { Log.data.info("Purged \(purged) expired brews from the trash") }
            } catch {
                Log.data.error("Trash purge failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
