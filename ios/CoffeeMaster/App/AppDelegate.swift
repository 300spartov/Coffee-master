import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Process-wide setup: analytics, crash reporting, push registration.
        // Colors and bar appearance: `ThemeAppearance` (applied per window in `AppRouter`).
        // Dependencies: Factory registrations in `DI/Container+App.swift`.
        return true
    }
}
