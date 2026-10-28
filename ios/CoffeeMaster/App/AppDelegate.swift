import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    /// Single dependency graph for the process, shared by all scenes.
    let container = AppContainer()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Process-wide setup: appearance, analytics, crash reporting, push registration.
        UINavigationBar.appearance().prefersLargeTitles = true
        return true
    }
}
