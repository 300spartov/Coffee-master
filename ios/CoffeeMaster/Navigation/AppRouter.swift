import UIKit
import FactoryKit
import AppCore
import BeansFeature
import BrewFeature
import JournalFeature
import ProfileFeature
import CompareFeature
import DeepLinks
import DevicesFeature
import DesignSystem
import Navigation
import SettingsFeature

/// Root of the navigation tree: owns the window, the tab bar, one `Flow` per tab and the
/// app-wide Brew action. Every external entry point ends up in `handle(_:)`.
///
/// The Brew action isn't a tab (tabs are for navigation): it's a button in the Journal's top bar
/// (`JournalFlow` installs it). The tab bar minimizes while scrolling (iOS 26), and the top bar keeps
/// the Brew button reachable.
final class AppRouter {
    private let window: UIWindow
    private let parser = DeepLinkParser()
    private let tabBarController = UITabBarController()
    private var flows: [any Flow] = []
    private var journalFlow: JournalFlow?
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
        } else {
            brewFlow?.resumeIfNeeded()
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
        let journal = JournalFlow(module: JournalModule(), compareModule: CompareModule(), startBrew: { [weak self] in self?.startBrew() })
        journalFlow = journal
        return [
            journal,
            BeansFlow(module: BeansModule()),
            DevicesFlow(module: DevicesModule()),
            ProfileFlow(profileModule: ProfileModule(), module: SettingsModule(), journalModule: JournalModule()),
        ]
    }

    private func buildTabs() {
        flows = makeFlows()
        flows.forEach { $0.start() }
        tabBarController.setViewControllers(flows.map(\.rootViewController), animated: false)
        brewFlow = BrewFlow(
            module: BrewModule(),
            beansModule: BeansModule(),
            devicesModule: DevicesModule(),
            presenter: tabBarController,
            showJournal: { [weak self] in self?.handle(.journal) },
            logBrew: { [weak self] in self?.logBrew() }
        )
        if #available(iOS 26, *) {
            tabBarController.tabBarMinimizeBehavior = .onScrollDown
        }
    }

    /// Screens resolve their strings when they're built, so a language change rebuilds every flow
    /// (and the Brew buttons), keeping the selected tab.
    private func rebuildForLanguageChange() {
        let selectedIndex = tabBarController.selectedIndex
        tabBarController.dismiss(animated: false)
        buildTabs()
        tabBarController.selectedIndex = selectedIndex
        // A brew in progress comes back in the new language.
        brewFlow?.resumeIfNeeded()
    }

    // MARK: - Brew action

    /// Logs a brew after the fact (the brew wizard's "Log a Brew"): closes what's open, shows the
    /// Journal and its log sheet.
    func logBrew() {
        guard let journal = journalFlow, let index = flows.firstIndex(where: { $0 === journal }) else { return }
        afterDismissingModals(animated: true) { [tabBarController] in
            tabBarController.selectedIndex = index
            journal.showLogBrew()
        }
    }

    func startBrew() {
        guard let brewFlow, !brewFlow.isPresented else { return }
        afterDismissingModals { brewFlow.start() }
    }

    /// Runs `action` once nothing is presented over the tabs (dismissing what is).
    private func afterDismissingModals(animated: Bool = false, _ action: @escaping () -> Void) {
        if tabBarController.presentedViewController != nil {
            tabBarController.dismiss(animated: animated, completion: action)
        } else {
            action()
        }
    }

    #if DEBUG
    /// Debug launch argument `-importWebJSON <path>`: imports a web export without the file picker.
    func importWebJSON(at url: URL) {
        Task { await WebImportCoordinator().importWebData(from: url) }
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
        afterDismissingModals { [tabBarController, flows] in
            tabBarController.selectedIndex = index
            flows[index].handle(link)
        }
    }
}
