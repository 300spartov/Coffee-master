import SwiftUI
import UIKit
import DeepLinks
import DesignSystem
import Navigation

/// Stand-in for a tab whose feature isn't built yet (Beans and Devices arrive in ROADMAP Phase 1).
@MainActor
final class PlaceholderFlow: Flow {
    private let title: String
    private let systemImage: String
    private let message: String
    private let router = StackRouter()

    var rootViewController: UIViewController { router.navigationController }

    init(title: String, systemImage: String, message: String) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        router.navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: systemImage),
            selectedImage: UIImage(systemName: systemImage + ".fill")
        )
    }

    func start() {
        let content = EmptyStateView(title: tr("Coming soon"), systemImage: systemImage, message: message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedGroupedBackground()
        router.setRoot(HostingController(rootView: content, title: title, largeTitleDisplayMode: .always))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool { false }
    func handle(_ deepLink: DeepLink) {}
}
