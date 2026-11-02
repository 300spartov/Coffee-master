import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import BeansFeature

/// Beans tab: bean list → edit (push); new bean (sheet).
final class BeansFlow: Flow {
    private let module: BeansModule
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()
    /// The "New Bean" sheet.
    private let modal = ModalSlot()

    var rootViewController: UIViewController { router.navigationController }

    init(module: BeansModule) {
        self.module = module
        router.navigationController.tabBarItem = UITabBarItem(title: tr("Beans"), systemImage: "leaf")
    }

    func start() {
        router.setRoot(module.makeBeanList(router: self))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        switch deepLink {
        case .beans, .beanDetail: true
        default: false
        }
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
        guard case .beanDetail(let rawID) = deepLink else { return }
        guard let id = UUID(uuidString: rawID) else { return showNotFound() }
        showBeanDetail(id: id)
    }
}

extension BeansFlow: BeanListRouting {
    func showBeanDetail(id: Bean.ID) {
        router.push(module.makeEditBean(id: id, router: self))
    }

    func showAddBean() {
        modal.presentSheet(module.makeAddBean(router: self), over: router)
    }
}

extension BeansFlow: BeanFormRouting {
    /// New bags come from the sheet, edits from a push.
    func beanForm(didFinish result: FormResult<Bean>) {
        switch result {
        case .added:
            modal.close()
            toasts.show(tr("Bean added"), style: .success)
        case .updated:
            router.pop()
            toasts.show(tr("Bean saved"), style: .success)
        case .cancelled:
            modal.close()
        case .deleted:
            router.popToRoot()
            toasts.show(tr("Bean deleted"), style: .success)
        case .notFound:
            showNotFound()
        }
    }

    /// A missing bag (also a malformed link): back on the list with a warning.
    private func showNotFound() {
        router.popToRoot(animated: false)
        toasts.show(tr("This bean no longer exists."), style: .warning)
    }
}
