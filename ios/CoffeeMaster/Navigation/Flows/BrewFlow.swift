import UIKit
import FactoryKit
import Domain
import DesignSystem
import Navigation
import BrewsFeature

/// The brew action's modal flow, presented full screen over the tabs.
/// Hosts the "New Brew" form until the brew wizard (ROADMAP Phase 2) replaces it.
@MainActor
final class BrewFlow {
    private let module: BrewsModule
    @Injected(\.toasts) private var toasts
    private var router: StackRouter?
    private weak var presenter: UIViewController?

    init(module: BrewsModule, presenter: UIViewController) {
        self.module = module
        self.presenter = presenter
    }

    var isPresented: Bool { router != nil }

    func start() {
        guard router == nil, let presenter else { return }
        let router = StackRouter()
        router.setRoot(module.makeNewBrew(router: self))
        router.navigationController.modalPresentationStyle = .fullScreen
        presenter.present(router.navigationController, animated: true)
        self.router = router
    }
}

extension BrewFlow: NewBrewRouting {
    func newBrewDidFinish(saved brew: Brew?) {
        router?.close()
        router = nil
        if brew != nil {
            toasts.show(Toast(tr("Brew saved"), style: .success))
        }
    }
}
