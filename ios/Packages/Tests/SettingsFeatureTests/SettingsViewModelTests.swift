import Foundation
import FactoryKit
import FactoryTesting
import Testing
import AppCore
@testable import SettingsFeature

@MainActor
final class SpySettingsRouter: SettingsRouting {
    private(set) var calls: [String] = []
    func showAbout() { calls.append("about") }
    func showNewBrew() { calls.append("newBrew") }
    func showWebImport() { calls.append("webImport") }
    func showDesignSystem() { calls.append("designSystem") }
}

@Suite(.container)
@MainActor
struct SettingsViewModelTests {
    private let router = SpySettingsRouter()

    private func makePreferences() -> AppPreferences {
        let preferences = AppPreferences(defaults: UserDefaults(suiteName: "SettingsViewModelTests.\(UUID().uuidString)")!)
        Container.shared.preferences.register { preferences }
        return preferences
    }

    @Test func hapticsToggleIsPersisted() {
        let preferences = makePreferences()
        let viewModel = SettingsViewModel(router: router)
        #expect(viewModel.hapticsEnabled)

        viewModel.hapticsEnabled = false

        #expect(!preferences.hapticsEnabled)
        #expect(!SettingsViewModel(router: router).hapticsEnabled)
    }

    @Test func actionsRoute() {
        _ = makePreferences()
        let viewModel = SettingsViewModel(router: router)

        viewModel.didTapAbout()
        viewModel.didTapNewBrew()
        viewModel.didTapWebImport()
        viewModel.didTapDesignSystem()

        #expect(router.calls == ["about", "newBrew", "webImport", "designSystem"])
    }
}
