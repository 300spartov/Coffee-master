import UIKit
import AppCore
import FactoryKit
import Navigation
public struct SettingsModule {
    public init() {}

    /// `title`: the screen is hosted by Profile for now, which names it.
    public func makeSettings(router: any SettingsRouting, title: String) -> UIViewController {
        let viewModel = SettingsViewModel(router: router)
        return HostingController(
            rootView: SettingsView(viewModel: viewModel),
            title: title,
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
