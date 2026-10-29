import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import BrewsFeature

/// Journal tab: brew list → detail. Starting a brew goes through the app-wide Brew action.
@MainActor
final class JournalFlow: Flow {
    private let module: BrewsModule
    private let startBrew: () -> Void
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()

    var rootViewController: UIViewController { router.navigationController }

    init(module: BrewsModule, startBrew: @escaping () -> Void) {
        self.module = module
        self.startBrew = startBrew
        router.navigationController.tabBarItem = UITabBarItem(
            title: tr("Journal"),
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            selectedImage: UIImage(systemName: "list.bullet.rectangle.portrait.fill")
        )
    }

    func start() {
        router.setRoot(module.makeBrewList(router: self))
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
            toasts.show(Toast(tr("This brew no longer exists."), style: .warning))
            return
        }
        router.push(module.makeBrewDetail(id: id, router: self), animated: false)
    }
}

extension JournalFlow: BrewListRouting {
    func showBrewDetail(id: Brew.ID) {
        router.push(module.makeBrewDetail(id: id, router: self))
    }

    func showNewBrew() {
        startBrew()
    }
}

extension JournalFlow: BrewDetailRouting {
    func brewDetailDidDelete(id: Brew.ID) {
        router.pop()
        toasts.show(Toast(tr("Brew deleted"), style: .success))
    }
}
