import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import DevicesFeature

/// Devices tab: category grid → category (push); add / edit a device (sheet).
final class DevicesFlow: Flow {
    private let module: DevicesModule
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()
    private var modalRouter: StackRouter?
    private var isEditingDevice = false

    var rootViewController: UIViewController { router.navigationController }

    init(module: DevicesModule) {
        self.module = module
        router.navigationController.tabBarItem = UITabBarItem(
            title: tr("Devices"),
            image: UIImage(systemName: "wrench.and.screwdriver"),
            selectedImage: UIImage(systemName: "wrench.and.screwdriver.fill")
        )
    }

    func start() {
        router.setRoot(module.makeCategories(router: self))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        deepLink == .devices
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
    }

    /// The open sheet, if it's really still on screen (`AppRouter` may have dismissed it for a deep link).
    private var openModal: StackRouter? {
        modalRouter?.isPresented == true ? modalRouter : nil
    }

    private func presentForm(_ form: UIViewController, editing: Bool) {
        guard openModal == nil else { return }
        isEditingDevice = editing
        let modal = router.presentStack(root: form) { sheet in
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        modal.onInteractiveDismiss = { [weak self] in self?.modalRouter = nil }
        modalRouter = modal
    }

    private func closeForm() {
        modalRouter?.close()
        modalRouter = nil
    }
}

extension DevicesFlow: DeviceCategoriesRouting {
    func showCategory(_ type: DeviceType) {
        router.push(module.makeCatalog(type: type, router: self))
    }
}

extension DevicesFlow: DeviceCatalogRouting {
    func showAddDevice(type: DeviceType) {
        presentForm(module.makeAddDevice(type: type, router: self), editing: false)
    }

    func showEditDevice(id: Device.ID) {
        presentForm(module.makeEditDevice(id: id, router: self), editing: true)
    }
}

extension DevicesFlow: DeviceFormRouting {
    func deviceFormDidFinish(saved device: Device?) {
        closeForm()
        if device != nil {
            toasts.show(isEditingDevice ? tr("Device saved") : tr("Device added"), style: .success)
        }
    }

    func deviceFormDidDelete(id: Device.ID) {
        closeForm()
        toasts.show(tr("Device removed"), style: .success)
    }

    func deviceFormNotFound(id: Device.ID) {
        closeForm()
        toasts.show(tr("This device no longer exists."), style: .warning)
    }
}
