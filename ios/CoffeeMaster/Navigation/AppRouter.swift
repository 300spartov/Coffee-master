import UIKit
import FactoryKit
import AppCore
import BrewsFeature
import DeepLinks
import DesignSystem
import Navigation
import SettingsFeature

/// Root of the navigation tree: owns the window, the tab bar, one `Flow` per tab and the
/// app-wide Brew action. Every external entry point ends up in `handle(_:)`.
///
/// The Brew action isn't a tab (tabs are for navigation): it's an accent button in the Journal's top
/// bar, a prominent Liquid Glass button on iOS 26. The tab bar minimizes while scrolling (iOS 26),
/// and the top bar keeps the Brew button reachable.
final class AppRouter {
    private let window: UIWindow
    private let parser = DeepLinkParser()
    private let tabBarController = UITabBarController()
    private var flows: [any Flow] = []
    private var brewFlow: BrewFlow?
    /// A link that arrived before `start()` (or while the UI wasn't ready, e.g. behind onboarding / login).
    private var pendingDeepLink: DeepLink?
    private var languageObserver: Task<Void, Never>?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        // Before any view controller exists, so every bar picks up the themed appearance.
        ThemeAppearance.apply(to: window)
        buildTabs()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        Container.shared.toastCenter().attach(to: window)

        if let link = pendingDeepLink {
            pendingDeepLink = nil
            handle(link)
        }

        languageObserver = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .appLanguageDidChange) {
                self?.rebuildForLanguageChange()
            }
        }
    }

    // MARK: - Tabs

    /// Order here = tab order. Adding a tab = adding a Flow.
    private func makeFlows() -> [any Flow] {
        [
            JournalFlow(module: BrewsModule(), startBrew: { [weak self] in self?.startBrew() }),
            PlaceholderFlow(title: tr("Beans"), systemImage: "leaf", message: tr("Your coffee bags will live here.")) { link in
                switch link {
                case .beans, .beanDetail: true
                default: false
                }
            },
            PlaceholderFlow(title: tr("Devices"), systemImage: "wrench.and.screwdriver", message: tr("Your brewing equipment will live here.")) { link in
                link == .devices
            },
            ProfileFlow(module: SettingsModule(), startBrew: { [weak self] in self?.startBrew() }),
        ]
    }

    private func buildTabs() {
        flows = makeFlows()
        flows.forEach { $0.start() }
        tabBarController.setViewControllers(flows.map(\.rootViewController), animated: false)
        brewFlow = BrewFlow(module: BrewsModule(), presenter: tabBarController)
        installBrewAction()
    }

    private func installBrewAction() {
        if #available(iOS 26, *) {
            tabBarController.tabBarMinimizeBehavior = .onScrollDown
        }
        // Only the Journal, where brews live. Other entry points: `brew/new`, Profile → "Log a New Brew".
        guard let journal = flows.first(where: { $0 is JournalFlow }),
              let root = (journal.rootViewController as? UINavigationController)?.viewControllers.first
        else { return }
        root.navigationItem.rightBarButtonItem = makeBrewButton()
    }

    /// Accent "Brew" button: prominent (accent-filled glass) on iOS 26, accent-tinted before.
    private func makeBrewButton() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            title: tr("Brew"),
            image: UIImage(systemName: "cup.and.heat.waves.fill"),
            primaryAction: UIAction { [weak self] _ in self?.startBrew() }
        )
        if #available(iOS 26, *) {
            item.style = .prominent
        } else {
            item.style = .done
        }
        item.tintColor = .theme.accent
        item.accessibilityLabel = tr("Start a Brew")
        item.accessibilityIdentifier = "brew.button"
        return item
    }

    /// Screens resolve their strings when they're built, so a language change rebuilds every flow
    /// (and the Brew buttons), keeping the selected tab.
    private func rebuildForLanguageChange() {
        let selectedIndex = tabBarController.selectedIndex
        tabBarController.dismiss(animated: false)
        buildTabs()
        tabBarController.selectedIndex = selectedIndex
    }

    // MARK: - Brew action

    func startBrew() {
        guard let brewFlow, !brewFlow.isPresented else { return }
        if tabBarController.presentedViewController != nil {
            tabBarController.dismiss(animated: false) { brewFlow.start() }
        } else {
            brewFlow.start()
        }
    }

    #if DEBUG
    /// Debug launch argument `-importWebJSON <path>`: imports a web export without the file picker.
    func importWebJSON(at url: URL) {
        guard let profile = flows.compactMap({ $0 as? ProfileFlow }).first else { return }
        Task { await profile.importWebData(from: url) }
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
        Log.deepLink.info("Routing \(String(describing: link), privacy: .public)")

        if link == .newBrew {
            startBrew()
            return
        }
        guard let index = flows.firstIndex(where: { $0.canHandle(link) }) else {
            Log.deepLink.error("No flow handles \(String(describing: link), privacy: .public)")
            return
        }

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
