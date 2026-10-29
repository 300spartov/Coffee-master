import FactoryKit
import Foundation
import AppCore
import DataLayer
import Domain
import DesignSystem
import Navigation
import WidgetsShared

// Composition root — the only place that knows concrete implementations.
//
// - Keys for shared protocols live in their modules (`Container+Domain`, `Container+DesignSystem`, …)
//   with preview-safe defaults. Real implementations are registered below in `autoRegister()`,
//   which Factory runs once before the first resolution.
// - App-only services (store, import, toast center) are declared here.
// - Tests and previews override anything with `Container.shared.<key>.register { … }`.
// - Scope: `.cached` — one instance per container (the app has one: `Container.shared`).
//   A fresh container (tests, `.container` trait) starts with fresh instances.

extension Container {
    /// On-disk Core Data store. If it can't be opened (e.g. a corrupted file) the app still starts
    /// on an in-memory store and the failure is logged, rather than crashing at launch.
    var persistence: Factory<PersistenceController> {
        self {
            do {
                return try PersistenceController()
            } catch {
                Log.data.fault("Falling back to in-memory store: \(error.localizedDescription, privacy: .public)")
                // An in-memory store at /dev/null can't fail to open.
                return try! PersistenceController(location: .inMemory)
            }
        }.cached
    }

    var webImportService: Factory<WebImportService> {
        self { WebImportService(persistence: self.persistence()) }.cached
    }

    var toastCenter: Factory<ToastCenter> {
        self { @MainActor in ToastCenter() }.cached
    }
}

extension Container: @retroactive AutoRegistering {
    public func autoRegister() {
        brewRepository.register {
            WidgetSyncingBrewRepository(
                wrapped: CoreDataBrewRepository(persistence: self.persistence()),
                snapshotStore: WidgetSnapshotStore()
            )
        }
        trashRepository.register { CoreDataTrashRepository(persistence: self.persistence()) }
        beanRepository.register { CoreDataBeanRepository(persistence: self.persistence()) }
        deviceRepository.register { CoreDataDeviceRepository(persistence: self.persistence()) }
        filterPackRepository.register { CoreDataFilterPackRepository(persistence: self.persistence()) }
        profileRepository.register { CoreDataProfileRepository(persistence: self.persistence()) }
        suggestionsRepository.register { CoreDataSuggestionsRepository(persistence: self.persistence()) }
        brewTimer.register { LiveActivityBrewTimerService() }
        toasts.register { @MainActor in self.toastCenter() }
    }
}
