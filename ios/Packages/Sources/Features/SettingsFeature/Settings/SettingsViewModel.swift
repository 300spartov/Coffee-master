import Foundation
import Observation
import AppCore
import Factory

@MainActor
@Observable
final class SettingsViewModel {
    private enum Keys {
        static let haptics = "settings.hapticsEnabled"
    }

    @ObservationIgnored @Injected(\.appVersion) var appVersion

    var hapticsEnabled: Bool = true {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @ObservationIgnored @Injected(\.userDefaults) private var defaults
    @ObservationIgnored private weak var router: (any SettingsRouting)?

    init(router: any SettingsRouting) {
        self.router = router
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }

    func didTapAbout() {
        router?.showAbout()
    }

    func didTapNewBrew() {
        router?.showNewBrew()
    }

    func didTapWebImport() {
        router?.showWebImport()
    }
}
