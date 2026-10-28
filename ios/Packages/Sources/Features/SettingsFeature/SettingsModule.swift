import UIKit
import Navigation

@MainActor
public struct SettingsModule {
    public struct Dependencies {
        public let appVersion: String
        public let defaults: UserDefaults

        public init(appVersion: String, defaults: UserDefaults = .standard) {
            self.appVersion = appVersion
            self.defaults = defaults
        }
    }

    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func makeSettings(router: any SettingsRouting) -> UIViewController {
        let viewModel = SettingsViewModel(
            appVersion: dependencies.appVersion,
            defaults: dependencies.defaults,
            router: router
        )
        return HostingController(
            rootView: SettingsView(viewModel: viewModel),
            title: String(localized: "Settings"),
            largeTitleDisplayMode: .always
        )
    }

    public func makeAbout() -> UIViewController {
        HostingController(
            rootView: AboutView(appVersion: dependencies.appVersion),
            title: String(localized: "About"),
            hidesBottomBarWhenPushed: true
        )
    }
}
