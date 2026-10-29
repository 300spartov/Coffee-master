import UIKit
import AppCore
import FactoryKit
import Navigation

@MainActor
public struct SettingsModule {
    public init() {}

    public func makeSettings(router: any SettingsRouting) -> UIViewController {
        let viewModel = SettingsViewModel(router: router)
        return HostingController(
            rootView: SettingsView(viewModel: viewModel),
            title: tr("Settings"),
            largeTitleDisplayMode: .always
        )
    }

    public func makeAbout() -> UIViewController {
        HostingController(
            rootView: AboutView(appVersion: Container.shared.appVersion()),
            title: tr("About"),
            hidesBottomBarWhenPushed: true
        )
    }
}
