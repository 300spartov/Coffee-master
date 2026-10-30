import UIKit
import FactoryKit
import Domain
import DesignSystem
import Navigation
import BrewsFeature

/// The brew action's modal flow, presented full screen over the tabs.
/// Hosts the "New Brew" form until the brew wizard (ROADMAP Phase 2) replaces it.
final class BrewFlow {
    private let module: BrewsModule
    @Injected(\.toasts) private var toasts
    private var router: StackRouter?
    private weak var presenter: UIViewController?

    init(module: BrewsModule, presenter: UIViewController) {
        self.module = module
        self.presenter = presenter
    }

    /// Whether the brew screen is really still on screen (`AppRouter` may have dismissed it for a deep link).
    var isPresented: Bool { router?.isPresented == true }

    func start() {
        guard !isPresented, let presenter else { return }
        router = StackRouter.presentStack(root: module.makeNewBrew(router: self), from: presenter, style: .fullScreen)
    }
}

extension BrewFlow: NewBrewRouting {
    func newBrewDidFinish(saved brew: Brew?) {
        router?.close()
        router = nil
        if brew != nil {
            toasts.show(tr("Brew saved"), style: .success)
        }
    }
}
