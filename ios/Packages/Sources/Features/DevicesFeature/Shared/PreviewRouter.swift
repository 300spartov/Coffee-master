#if DEBUG
import Domain

/// No-op router for SwiftUI previews. Retained by `shared` because view models hold routers weakly.
final class PreviewRouter: DeviceCategoriesRouting, DeviceCatalogRouting, DeviceFormRouting, FilterPacksRouting, FilterPackFormRouting {
    static let shared = PreviewRouter()

    func showCategory(_ type: DeviceType) {}
    func showFilterPacks() {}
    func showAddDevice(type: DeviceType) {}
    func showEditDevice(id: Device.ID) {}
    func deviceForm(didFinish result: FormResult<Device>) {}
    func showAddFilterPack() {}
    func showEditFilterPack(id: FilterPack.ID) {}
    func filterPackForm(didFinish result: FormResult<FilterPack>) {}
}
#endif
