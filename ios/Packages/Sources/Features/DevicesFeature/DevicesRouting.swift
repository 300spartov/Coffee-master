import Domain

// Navigation intents emitted by the feature's view models.
// The feature doesn't know *how* navigation happens; a Flow in the app target implements these.

public protocol DeviceCategoriesRouting: AnyObject {
    func showCategory(_ type: DeviceType)
    func showFilterPacks()
}

public protocol DeviceCatalogRouting: AnyObject {
    func showAddDevice(type: DeviceType)
    func showEditDevice(id: Device.ID)
}

public protocol DeviceFormRouting: AnyObject {
    func deviceForm(didFinish result: FormResult<Device>)
}

public protocol FilterPacksRouting: AnyObject {
    func showAddFilterPack()
    func showEditFilterPack(id: FilterPack.ID)
}

public protocol FilterPackFormRouting: AnyObject {
    func filterPackForm(didFinish result: FormResult<FilterPack>)
}
