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
    /// `device` is `nil` when the user cancelled.
    func deviceFormDidFinish(saved device: Device?)
    func deviceFormDidDelete(id: Device.ID)
    /// The device being edited doesn't exist (anymore).
    func deviceFormNotFound(id: Device.ID)
}

public protocol FilterPacksRouting: AnyObject {
    func showAddFilterPack()
    func showEditFilterPack(id: FilterPack.ID)
}

public protocol FilterPackFormRouting: AnyObject {
    /// `pack` is `nil` when the user cancelled.
    func filterPackFormDidFinish(saved pack: FilterPack?)
    func filterPackFormDidDelete(id: FilterPack.ID)
    /// The pack being edited doesn't exist (anymore).
    func filterPackFormNotFound(id: FilterPack.ID)
}
