import UIKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import BrewsFeature

/// Brews tab: list → detail (push), new brew (modal stack).
@MainActor
final class BrewsFlow: Flow {
    private let module: BrewsModule
    private let toasts: any ToastPresenting
    private let router = StackRouter()
    private var modalRouter: StackRouter?

    var rootViewController: UIViewController { router.navigationController }

    init(module: BrewsModule, toasts: any ToastPresenting) {
        self.module = module
        self.toasts = toasts
        router.navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Brews"),
            image: UIImage(systemName: "cup.and.saucer"),
            selectedImage: UIImage(systemName: "cup.and.saucer.fill")
        )
    }

    func start() {
        router.setRoot(module.makeBrewList(router: self))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        switch deepLink {
        case .brews, .brewDetail, .newBrew: true
        case .settings, .about: false
        }
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
        switch deepLink {
        case .brewDetail(let rawID):
            guard let id = UUID(uuidString: rawID) else {
                toasts.show(Toast(String(localized: "This brew no longer exists."), style: .warning))
                return
            }
            router.push(module.makeBrewDetail(id: id, router: self), animated: false)
        case .newBrew:
            showNewBrew()
        case .brews, .settings, .about:
            break
        }
    }
}

extension BrewsFlow: BrewListRouting {
    func showBrewDetail(id: Brew.ID) {
        router.push(module.makeBrewDetail(id: id, router: self))
    }

    func showNewBrew() {
        let modal = router.presentStack(root: module.makeNewBrew(router: self)) { sheet in
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        modal.onInteractiveDismiss = { [weak self] in self?.modalRouter = nil }
        modalRouter = modal
    }
}

extension BrewsFlow: BrewDetailRouting {
    func brewDetailDidDelete(id: Brew.ID) {
        router.pop()
        toasts.show(Toast(String(localized: "Brew deleted"), style: .success))
    }
}

extension BrewsFlow: NewBrewRouting {
    func newBrewDidFinish(saved brew: Brew?) {
        modalRouter?.close()
        modalRouter = nil
        if brew != nil {
            toasts.show(Toast(String(localized: "Brew saved"), style: .success))
        }
    }
}
