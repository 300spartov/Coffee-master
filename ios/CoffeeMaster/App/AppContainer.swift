import Foundation
import AppCore
import Domain
import DataLayer
import WidgetsShared
import Navigation
import BrewsFeature
import SettingsFeature

/// Composition root — the only place that knows concrete implementations.
/// Swap implementations here (e.g. a persistent repository or mocks for UI tests);
/// features only see protocols.
@MainActor
final class AppContainer {
    // MARK: Services (singletons for the app's lifetime)

    let toastCenter = ToastCenter()

    /// On-disk Core Data store. If it can't be opened (e.g. corrupted file) the app still starts
    /// on an in-memory store and the failure is logged, rather than crashing at launch.
    let persistence: PersistenceController = {
        do {
            return try PersistenceController()
        } catch {
            Log.data.fault("Falling back to in-memory store: \(error.localizedDescription, privacy: .public)")
            // An in-memory store at /dev/null can't fail to open.
            return try! PersistenceController(location: .inMemory)
        }
    }()

    lazy var brewRepository: any BrewRepository = WidgetSyncingBrewRepository(
        wrapped: CoreDataBrewRepository(persistence: persistence),
        snapshotStore: WidgetSnapshotStore()
    )

    lazy var webImportService = WebImportService(persistence: persistence)

    lazy var brewTimer: any BrewTimerService = LiveActivityBrewTimerService()

    // MARK: Feature modules (cheap factories, built on demand)

    var brewsModule: BrewsModule {
        BrewsModule(dependencies: .init(repository: brewRepository, brewTimer: brewTimer))
    }

    var settingsModule: SettingsModule {
        SettingsModule(dependencies: .init(appVersion: Bundle.main.appVersion))
    }
}

private extension Bundle {
    var appVersion: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }
}
