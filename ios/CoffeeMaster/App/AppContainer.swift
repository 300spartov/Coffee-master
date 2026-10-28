import Foundation
import Domain
import DataLayer
import WidgetsShared
import BrewsFeature
import SettingsFeature

/// Composition root — the only place that knows concrete implementations.
/// Swap implementations here (e.g. a persistent repository or mocks for UI tests);
/// features only see protocols.
@MainActor
final class AppContainer {
    // MARK: Services (singletons for the app's lifetime)

    lazy var brewRepository: any BrewRepository = WidgetSyncingBrewRepository(
        wrapped: InMemoryBrewRepository(),
        snapshotStore: WidgetSnapshotStore()
    )

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
