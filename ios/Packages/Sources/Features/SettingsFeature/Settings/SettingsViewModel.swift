import Foundation
import Observation
import AppCore
import FactoryKit
@Observable
final class SettingsViewModel {
    @ObservationIgnored @Injected(\.appVersion) var appVersion

    var hapticsEnabled: Bool = true {
        didSet { preferences.hapticsEnabled = hapticsEnabled }
    }

    /// In-app language. Changing it persists the choice; the app then rebuilds its screens.
    var language: AppLanguage = LanguageSettings.shared.current {
        didSet { LanguageSettings.shared.set(language) }
    }

    @ObservationIgnored @Injected(\.preferences) private var preferences
    @ObservationIgnored private weak var router: (any SettingsRouting)?

    init(router: any SettingsRouting) {
        self.router = router
        hapticsEnabled = preferences.hapticsEnabled
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

    func didTapDesignSystem() {
        router?.showDesignSystem()
    }
}
