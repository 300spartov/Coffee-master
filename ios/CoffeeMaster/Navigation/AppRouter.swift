import UIKit
import AppCore
import DeepLinks
import Navigation

/// Root of the navigation tree: owns the window, the tab bar and one `Flow` per tab.
/// Every external entry point ends up in `handle(_:)`.
@MainActor
final class AppRouter {
    private let window: UIWindow
    private let container: AppContainer
    private let parser = DeepLinkParser()
    private let tabBarController = UITabBarController()
    private var flows: [any Flow] = []
    /// A link that arrived before `start()` (or while the UI wasn't ready, e.g. behind onboarding / login).
    private var pendingDeepLink: DeepLink?

    init(window: UIWindow, container: AppContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        flows = makeFlows()
        flows.forEach { $0.start() }
        tabBarController.setViewControllers(flows.map(\.rootViewController), animated: false)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        if let link = pendingDeepLink {
            pendingDeepLink = nil
            handle(link)
        }
    }

    /// Order here = tab order. Adding a tab = adding a Flow.
    private func makeFlows() -> [any Flow] {
        [
            BrewsFlow(module: container.brewsModule),
            SettingsFlow(
                module: container.settingsModule,
                openDeepLink: { [weak self] in self?.handle($0) }
            ),
        ]
    }

    // MARK: - Deep links

    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let link = parser.parse(url) else {
            Log.deepLink.error("Unsupported URL: \(url.absoluteString, privacy: .public)")
            return false
        }
        handle(link)
        return true
    }

    func handle(_ link: DeepLink) {
        guard !flows.isEmpty else {
            pendingDeepLink = link
            return
        }
        guard let index = flows.firstIndex(where: { $0.canHandle(link) }) else {
            Log.deepLink.error("No flow handles \(String(describing: link), privacy: .public)")
            return
        }
        Log.deepLink.info("Routing \(String(describing: link), privacy: .public)")

        // Start from a clean slate so a link always lands on the same screen.
        let route = { [tabBarController, flows] in
            tabBarController.selectedIndex = index
            flows[index].handle(link)
        }
        if tabBarController.presentedViewController != nil {
            tabBarController.dismiss(animated: false, completion: route)
        } else {
            route()
        }
    }
}
