import SwiftUI
import UIKit

/// Hosts a SwiftUI screen inside UIKit navigation and configures its navigation item.
///
/// SwiftUI views stay navigation-agnostic: no `NavigationStack`, no `NavigationLink`.
/// Titles and bar buttons are set here (by the feature module's builder), pushes happen in flows.
public final class HostingController<Content: View>: UIHostingController<Content> {
    public init(
        rootView: Content,
        title: String? = nil,
        largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .never,
        hidesBottomBarWhenPushed: Bool = false
    ) {
        super.init(rootView: rootView)
        self.title = title
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
        self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
