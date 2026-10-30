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
    /// The "New Bean" sheet while it's open.
    private var modalRouter: StackRouter?

    var rootViewController: UIViewController { router.navigationController }

    init(module: BeansModule) {
        self.module = module
        router.navigationController.tabBarItem = UITabBarItem(
            title: tr("Beans"),
            image: UIImage(systemName: "leaf"),
            selectedImage: UIImage(systemName: "leaf.fill")
        )
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
        guard let id = UUID(uuidString: rawID) else {
            toasts.show(tr("This bean no longer exists."), style: .warning)
            return
        }
        showBeanDetail(id: id)
    }
}

extension BeansFlow: BeanListRouting {
    func showBeanDetail(id: Bean.ID) {
        router.push(module.makeEditBean(id: id, router: self))
    }

    /// The "New Bean" sheet, if it's really still on screen (`AppRouter` may have dismissed it for a deep link).
    private var openModal: StackRouter? {
        modalRouter?.isPresented == true ? modalRouter : nil
    }

    func showAddBean() {
        guard openModal == nil else { return }
        let modal = router.presentStack(root: module.makeAddBean(router: self)) { sheet in
            sheet.detents = [.large()]
        }
        modal.onInteractiveDismiss = { [weak self] in self?.modalRouter = nil }
        modalRouter = modal
    }
}

extension BeansFlow: BeanFormRouting {
    func beanFormDidFinish(saved bean: Bean?) {
        if let modal = openModal {
            modal.close()
            modalRouter = nil
            if bean != nil { toasts.show(tr("Bean added"), style: .success) }
        } else {
            router.pop()
            if bean != nil { toasts.show(tr("Bean saved"), style: .success) }
        }
    }

    func beanFormDidDelete(id: Bean.ID) {
        router.popToRoot()
        toasts.show(tr("Bean deleted"), style: .success)
    }

    /// Same outcome as a malformed bean link: back on the list with a warning.
    func beanFormNotFound(id: Bean.ID) {
        router.popToRoot(animated: false)
        toasts.show(tr("This bean no longer exists."), style: .warning)
    }
}
