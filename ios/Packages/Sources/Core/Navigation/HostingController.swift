import SwiftUI
import UIKit
import AppCore
import DesignSystem

/// Hosts a SwiftUI screen inside UIKit navigation and configures its navigation item.
///
/// SwiftUI views stay navigation-agnostic: no `NavigationStack`, no `NavigationLink`.
/// Titles and bar buttons are set here (by the feature module's builder), pushes happen in flows.
public final class HostingController<Content: View>: UIHostingController<LocalizedRoot<Content>> {
    public init(
        rootView: Content,
        title: String? = nil,
        largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .never,
        hidesBottomBarWhenPushed: Bool = false
    ) {
        super.init(rootView: LocalizedRoot(content: rootView, locale: LanguageSettings.shared.current.locale))
        view.backgroundColor = .theme.background
        self.title = title
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
        self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

/// Applies the in-app language's locale to a screen, so dates, numbers and units format in that
/// language. Screens are rebuilt when the language changes (see `AppRouter`).
public struct LocalizedRoot<Content: View>: View {
    let content: Content
    let locale: Locale

    public var body: some View {
        content.environment(\.locale, locale)
    }
}
