import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private enum Keys {
        static let haptics = "settings.hapticsEnabled"
    }

    let appVersion: String

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private weak var router: (any SettingsRouting)?

    init(appVersion: String, defaults: UserDefaults, router: any SettingsRouting) {
        self.appVersion = appVersion
        self.defaults = defaults
        self.router = router
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }

    func didTapAbout() {
        router?.showAbout()
    }

    func didTapNewBrew() {
        router?.showNewBrew()
    }
}
