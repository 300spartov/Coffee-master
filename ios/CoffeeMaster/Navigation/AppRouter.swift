import UIKit
import FactoryKit
import AppCore
import BrewsFeature
import DeepLinks
import Navigation
import SettingsFeature

/// Root of the navigation tree: owns the window, the tab bar and one `Flow` per tab.
/// Every external entry point ends up in `handle(_:)`.
@MainActor
final class AppRouter {
    private let window: UIWindow
    private let parser = DeepLinkParser()
    private let tabBarController = UITabBarController()
    private var flows: [any Flow] = []
    /// A link that arrived before `start()` (or while the UI wasn't ready, e.g. behind onboarding / login).
    private var pendingDeepLink: DeepLink?
    private var languageObserver: NSObjectProtocol?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        // Before any view controller exists, so every bar picks up the themed appearance.
        ThemeAppearance.apply(to: window)
        flows = makeFlows()
        flows.forEach { $0.start() }
        tabBarController.setViewControllers(flows.map(\.rootViewController), animated: false)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        Container.shared.toastCenter().attach(to: window)

        if let link = pendingDeepLink {
            pendingDeepLink = nil
            handle(link)
        }

        languageObserver = NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuildForLanguageChange() }
        }
    }

    /// Screens resolve their strings when they're built, so a language change rebuilds every flow,
    /// keeping the selected tab.
    private func rebuildForLanguageChange() {
        let selectedIndex = tabBarController.selectedIndex
        tabBarController.dismiss(animated: false)
        flows = makeFlows()
        flows.forEach { $0.start() }
        tabBarController.setViewControllers(flows.map(\.rootViewController), animated: false)
        tabBarController.selectedIndex = selectedIndex
    }

    /// Order here = tab order. Adding a tab = adding a Flow.
    private func makeFlows() -> [any Flow] {
        [
            BrewsFlow(module: BrewsModule()),
            SettingsFlow(module: SettingsModule(), openDeepLink: { [weak self] in self?.handle($0) }),
        ]
    }

    #if DEBUG
    /// Debug launch argument `-importWebJSON <path>`: imports a web export without the file picker.
    func importWebJSON(at url: URL) {
        guard let settings = flows.compactMap({ $0 as? SettingsFlow }).first else { return }
        Task { await settings.importWebData(from: url) }
    }
    #endif

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
