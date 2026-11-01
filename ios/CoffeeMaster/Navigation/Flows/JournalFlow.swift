import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import JournalFeature

/// Journal tab: the feed → a brew to edit. Starting a brew goes through the app-wide Brew action.
final class JournalFlow: Flow {
    private let module: JournalModule
    private let startBrew: () -> Void
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()

    var rootViewController: UIViewController { router.navigationController }

    init(module: JournalModule, startBrew: @escaping () -> Void) {
        self.module = module
        self.startBrew = startBrew
        router.navigationController.tabBarItem = UITabBarItem(
            title: tr("Journal"),
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            selectedImage: UIImage(systemName: "list.bullet.rectangle.portrait.fill")
        )
    }

    func start() {
        router.setRoot(module.makeFeed(router: self))
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
        guard let id = UUID(uuidString: rawID) else {
            toasts.show(tr("This brew no longer exists."), style: .warning)
            return
        }
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
}

extension JournalFlow: BrewFormRouting {
    func brewFormDidSave(_ brew: Brew) {
        router.pop()
        toasts.show(tr("Brew updated"), style: .success)
    }

    func brewFormDidDelete(id: Brew.ID) {
        router.pop()
        toasts.show(tr("Brew deleted"), style: .success)
    }

    /// Same outcome as a malformed brew link: back on the Journal with a warning.
    func brewFormNotFound(id: Brew.ID) {
        router.popToRoot(animated: false)
        toasts.show(tr("This brew no longer exists."), style: .warning)
    }
}
