import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import JournalFeature
import CompareFeature

/// Journal tab: the feed → a brew to edit or the comparison (push); logging a brew after the fact and the filters (sheets). Starting a
/// brew goes through the app-wide Brew action.
final class JournalFlow: Flow {
    private let module: JournalModule
    private let compareModule: CompareModule
    private let startBrew: () -> Void
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()
    /// The "Log a Brew" or filter sheet.
    private let modal = ModalSlot()

    var rootViewController: UIViewController { router.navigationController }

    init(module: JournalModule, compareModule: CompareModule, startBrew: @escaping () -> Void) {
        self.module = module
        self.compareModule = compareModule
        self.startBrew = startBrew
        router.navigationController.tabBarItem = UITabBarItem(title: tr("Journal"), systemImage: "list.bullet.rectangle.portrait")
    }

    /// The feed, with the app-wide Brew button rightmost in its top bar (the feed's "+" beside it).
    func start() {
        let feed = module.makeFeed(router: self)
        feed.navigationItem.rightBarButtonItems = [makeBrewButton()] + (feed.navigationItem.rightBarButtonItems ?? [])
        router.setRoot(feed)
    }

    /// Accent "Brew" button. On iOS 26 it shares one Liquid Glass capsule with the feed's "+" (a
    /// `.prominent` item would get a separate filled capsule); before, it's an accent-tinted done item.
    private func makeBrewButton() -> UIBarButtonItem {
        let item = UIBarButtonItem(title: tr("Brew"), image: UIImage(systemName: "cup.and.heat.waves.fill"), primaryAction: UIAction { [weak self] _ in
            self?.startBrew()
        })
        if #unavailable(iOS 26) {
            item.style = .done
        }
        item.tintColor = .theme.accent
        item.accessibilityLabel = tr("Start a Brew")
        item.accessibilityIdentifier = "brew.button"
        return item
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        switch deepLink {
        case .journal, .brewDetail: true
        default: false
        }
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
        guard case .brewDetail(let rawID) = deepLink else { return }
        guard let id = UUID(uuidString: rawID) else { return showNotFound() }
        router.push(module.makeBrewForm(id: id, router: self), animated: false)
    }
}

extension JournalFlow: FeedRouting {
    func showBrew(id: Brew.ID) {
        router.push(module.makeBrewForm(id: id, router: self))
    }

    func showNewBrew() {
        startBrew()
    }

    func showCompare(brewIDs: [Brew.ID]) {
        router.push(compareModule.makeCompare(brewIDs: brewIDs))
    }

    func showLogBrew() {
        modal.presentSheet(module.makeLogBrew(router: self), over: router)
    }

    func showFilters(_ filters: FeedFilters) {
        modal.presentSheet(module.makeFilters(filters, router: self), over: router, size: .resizable)
    }
}

extension JournalFlow: FeedFiltersRouting {
    func feedFiltersDidFinish() {
        modal.close()
    }
}

extension JournalFlow: BrewFormRouting {
    /// Logging happens in the sheet, editing in a push.
    func brewForm(didFinish result: FormResult<Brew>) {
        switch result {
        case .added:
            modal.close()
            toasts.show(tr("Brew added"), style: .success)
        case .updated:
            router.pop()
            toasts.show(tr("Brew updated"), style: .success)
        case .cancelled:
            modal.close()
        case .deleted:
            // The form already showed "Brew deleted" with Undo.
            router.pop()
        case .notFound:
            showNotFound()
        }
    }

    /// A missing brew (also a malformed link): back on the Journal with a warning.
    private func showNotFound() {
        router.popToRoot(animated: false)
        toasts.show(tr("This brew no longer exists."), style: .warning)
    }
}
