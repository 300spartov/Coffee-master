import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import BeansFeature

/// Beans tab: bean list -> detail/edit.
final class BeansFlow: Flow {
    private let module: BeansModule
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()

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
        // Step 1.2 will implement the Bean detail/edit screen.
    }

    func showAddBean() {
        // Step 1.2 will implement the Add Bean modal.
    }
}
