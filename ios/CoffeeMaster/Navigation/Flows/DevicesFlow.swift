import UIKit
import FactoryKit
import Domain
import DeepLinks
import DesignSystem
import Navigation
import DevicesFeature

/// Devices tab: category grid → category or filter packs (push); add / edit a device or filter pack (sheet).
final class DevicesFlow: Flow {
    private let module: DevicesModule
    @Injected(\.toasts) private var toasts
    private let router = StackRouter()
    /// The add / edit sheet.
    private let modal = ModalSlot()
    /// Whether the open form edits an existing item (picks "saved" over "added" for the toast).
    private var isEditingItem = false

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

    /// Opens a form sheet unless one is already open. `detents`: the device form is short enough
    /// for half height; the filter pack form isn't.
    private func presentForm(
        editing: Bool,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        _ makeForm: () -> UIViewController
    ) {
        modal.present {
            isEditingItem = editing
            return router.presentStack(root: makeForm()) { sheet in
                sheet.detents = detents
                sheet.prefersGrabberVisible = true
            }
        }
    }
}

extension DevicesFlow: DeviceCategoriesRouting {
    func showCategory(_ type: DeviceType) {
        router.push(module.makeCatalog(type: type, router: self))
    }

    func showFilterPacks() {
        router.push(module.makeFilterPacks(router: self))
    }
}

extension DevicesFlow: DeviceCatalogRouting {
    func showAddDevice(type: DeviceType) {
        presentForm(editing: false) { module.makeAddDevice(type: type, router: self) }
    }

    func showEditDevice(id: Device.ID) {
        presentForm(editing: true) { module.makeEditDevice(id: id, router: self) }
    }
}

extension DevicesFlow: DeviceFormRouting {
    func deviceFormDidFinish(saved device: Device?) {
        modal.close()
        if device != nil {
            toasts.show(isEditingItem ? tr("Device saved") : tr("Device added"), style: .success)
        }
    }

    func deviceFormDidDelete(id: Device.ID) {
        modal.close()
        toasts.show(tr("Device removed"), style: .success)
    }

    func deviceFormNotFound(id: Device.ID) {
        modal.close()
        toasts.show(tr("This device no longer exists."), style: .warning)
    }
}

extension DevicesFlow: FilterPacksRouting {
    func showAddFilterPack() {
        presentForm(editing: false, detents: [.large()]) { module.makeAddFilterPack(router: self) }
    }

    func showEditFilterPack(id: FilterPack.ID) {
        presentForm(editing: true, detents: [.large()]) { module.makeEditFilterPack(id: id, router: self) }
    }
}

extension DevicesFlow: FilterPackFormRouting {
    func filterPackFormDidFinish(saved pack: FilterPack?) {
        modal.close()
        if pack != nil {
            toasts.show(isEditingItem ? tr("Filter pack saved") : tr("Filter pack added"), style: .success)
        }
    }

    func filterPackFormDidDelete(id: FilterPack.ID) {
        modal.close()
        toasts.show(tr("Filter pack removed"), style: .success)
    }

    func filterPackFormNotFound(id: FilterPack.ID) {
        modal.close()
        toasts.show(tr("This filter pack no longer exists."), style: .warning)
    }
}
