import UIKit
import AppCore
import FactoryKit
import Navigation
public struct SettingsModule {
    public init() {}

    /// Pushed from Profile.
    public func makeSettings(router: any SettingsRouting) -> UIViewController {
        HostingController(
            rootView: SettingsView(viewModel: SettingsViewModel(router: router)),
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
