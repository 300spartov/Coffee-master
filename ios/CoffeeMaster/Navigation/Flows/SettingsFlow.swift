import UIKit
import DeepLinks
import Navigation
import SettingsFeature

/// Settings tab. Shows how one flow reaches another feature: by emitting a deep link
/// that `AppRouter` routes, never by importing the other feature.
@MainActor
final class SettingsFlow: Flow {
    private let module: SettingsModule
    private let router = StackRouter()
    private let openDeepLink: (DeepLink) -> Void

    var rootViewController: UIViewController { router.navigationController }

    init(module: SettingsModule, openDeepLink: @escaping (DeepLink) -> Void) {
        self.module = module
        self.openDeepLink = openDeepLink
        router.navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Settings"),
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
    }

    func start() {
        router.setRoot(module.makeSettings(router: self))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        switch deepLink {
        case .settings, .about: true
        case .brews, .brewDetail, .newBrew: false
        }
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
        if deepLink == .about {
            router.push(module.makeAbout(), animated: false)
        }
    }
}

extension SettingsFlow: SettingsRouting {
    func showAbout() {
        router.push(module.makeAbout())
    }

    func showNewBrew() {
        openDeepLink(.newBrew)
    }
}
