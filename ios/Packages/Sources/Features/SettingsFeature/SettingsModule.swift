import UIKit
import AppCore
import Factory
import Navigation

@MainActor
public struct SettingsModule {
    public init() {}

    public func makeSettings(router: any SettingsRouting) -> UIViewController {
        let viewModel = SettingsViewModel(router: router)
        return HostingController(
            rootView: SettingsView(viewModel: viewModel),
            title: String(localized: "Settings"),
            largeTitleDisplayMode: .always
        )
    }

    public func makeAbout() -> UIViewController {
        HostingController(
            rootView: AboutView(appVersion: Container.shared.appVersion()),
            title: String(localized: "About"),
            hidesBottomBarWhenPushed: true
        )
    }
}
