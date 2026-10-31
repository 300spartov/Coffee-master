import UIKit
import FactoryKit
import Domain
import DesignSystem
import Navigation
import BrewFeature
import BrewsFeature

/// The brew action's modal flow, presented full screen over the tabs: the brew wizard.
/// Method pick (2.1) → the template "New Brew" form, until setup and rating (2.2–2.7) replace it.
final class BrewFlow {
    private let module: BrewModule
    private let brewsModule: BrewsModule
    @Injected(\.toasts) private var toasts
    private let modal = ModalSlot()
    private weak var presenter: UIViewController?

    init(module: BrewModule, brewsModule: BrewsModule, presenter: UIViewController) {
        self.module = module
        self.brewsModule = brewsModule
        self.presenter = presenter
    }

    /// Whether the brew screen is really still on screen (`AppRouter` may have dismissed it for a deep link).
    var isPresented: Bool { modal.isPresented }

    func start() {
        guard let presenter else { return }
        modal.present {
            StackRouter.presentStack(root: module.makeMethodGroups(router: self), from: presenter, style: .fullScreen)
        }
    }
}

extension BrewFlow: MethodPickRouting {
    func showMethods(in group: MethodGroup) {
        modal.current?.push(module.makeMethods(in: group, router: self))
    }

    func methodPickDidSelect(_ method: BrewMethod) {
        modal.current?.push(brewsModule.makeNewBrew(method: method, router: self))
    }

    func methodPickDidCancel() {
        modal.close()
    }
}

extension BrewFlow: NewBrewRouting {
    func newBrewDidSave(_ brew: Brew) {
        modal.close()
        toasts.show(tr("Brew saved"), style: .success)
    }
}
