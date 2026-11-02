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

    var rootViewController: UIViewController { router.navigationController }

    init(module: DevicesModule) {
        self.module = module
        router.navigationController.tabBarItem = UITabBarItem(title: tr("Devices"), systemImage: "wrench.and.screwdriver")
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

    /// Closes the form sheet and says how it went.
    private func finish<Item>(_ result: FormResult<Item>, added: String, saved: String, removed: String, missing: String) {
        modal.close()
        switch result {
        case .added: toasts.show(added, style: .success)
        case .updated: toasts.show(saved, style: .success)
        case .deleted: toasts.show(removed, style: .success)
        case .notFound: toasts.show(missing, style: .warning)
        case .cancelled: break
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
        modal.presentSheet(module.makeAddDevice(type: type, router: self), over: router, size: .resizable)
    }

    func showEditDevice(id: Device.ID) {
        modal.presentSheet(module.makeEditDevice(id: id, router: self), over: router, size: .resizable)
    }
}

extension DevicesFlow: DeviceFormRouting {
    func deviceForm(didFinish result: FormResult<Device>) {
        finish(result, added: tr("Device added"), saved: tr("Device saved"), removed: tr("Device removed"), missing: tr("This device no longer exists."))
    }
}

extension DevicesFlow: FilterPacksRouting {
    func showAddFilterPack() {
        modal.presentSheet(module.makeAddFilterPack(router: self), over: router)
    }

    func showEditFilterPack(id: FilterPack.ID) {
        modal.presentSheet(module.makeEditFilterPack(id: id, router: self), over: router)
    }
}

extension DevicesFlow: FilterPackFormRouting {
    func filterPackForm(didFinish result: FormResult<FilterPack>) {
        finish(result, added: tr("Filter pack added"), saved: tr("Filter pack saved"), removed: tr("Filter pack removed"), missing: tr("This filter pack no longer exists."))
    }
}
