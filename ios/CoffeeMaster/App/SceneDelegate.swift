import UIKit

/// Converts every system entry point into a URL and hands it to `AppRouter`:
/// custom-scheme URLs, universal links, widget / Live Activity taps (both arrive as URLs),
/// and Home Screen quick actions.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appRouter: AppRouter?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else { return }

        let window = UIWindow(windowScene: windowScene)
        let router = AppRouter(window: window, container: appDelegate.container)
        router.start()
        self.window = window
        appRouter = router

        // Cold start: links that launched the app.
        if let url = connectionOptions.urlContexts.first?.url {
            router.open(url)
        }
        if let activity = connectionOptions.userActivities.first {
            continueUserActivity(activity)
        }
        if let shortcut = connectionOptions.shortcutItem {
            handle(shortcut)
        }

        #if DEBUG
        // Launch argument for UI tests / scheme arguments: `-deeplink coffeemaster://brews/42`
        if let link = UserDefaults.standard.string(forKey: "deeplink"), let url = URL(string: link) {
            router.open(url)
        }
        // `-importWebJSON /path/to/export.json`
        if let path = UserDefaults.standard.string(forKey: "importWebJSON") {
            router.importWebJSON(at: URL(fileURLWithPath: path))
        }
        #endif
    }

    // Warm start: custom scheme, widget and Live Activity taps.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        appRouter?.open(url)
    }

    // Warm start: universal links.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        continueUserActivity(userActivity)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(handle(shortcutItem))
    }

    private func continueUserActivity(_ activity: NSUserActivity) {
        guard activity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = activity.webpageURL
        else { return }
        appRouter?.open(url)
    }

    /// Quick actions carry a deep-link URL in `type`, so they reuse the same routing.
    @discardableResult
    private func handle(_ shortcut: UIApplicationShortcutItem) -> Bool {
        guard let url = URL(string: shortcut.type) else { return false }
        return appRouter?.open(url) ?? false
    }
}
