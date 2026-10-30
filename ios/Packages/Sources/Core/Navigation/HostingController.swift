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

    // MARK: - Bar buttons

    /// A "+" on the right of the navigation bar.
    public func setAddButton(accessibilityLabel: String, identifier: String, action: @escaping () -> Void) {
        let item = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { _ in action() })
        item.accessibilityLabel = accessibilityLabel
        item.accessibilityIdentifier = identifier
        navigationItem.rightBarButtonItem = item
    }

    /// Cancel on the left, for a form presented modally. The form also can't be swiped away, so typed
    /// details aren't lost by accident; Cancel is the way out.
    public func setCancelButton(action: @escaping () -> Void) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { _ in action() })
        isModalInPresentation = true
    }

    // MARK: - Search

    private var searchUpdater: SearchUpdater?
    private var collapsesSearchWhileScrolling = false

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Shown on first appearance, then let the system tuck it away while scrolling.
        if collapsesSearchWhileScrolling {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }

    /// Adds the system search bar (`UISearchController`) to this screen's navigation bar and reports
    /// every text change to `onChange` (typically a view model's `query`).
    ///
    /// `collapsesWhileScrolling`: the bar is visible when the screen appears, collapses as the list
    /// scrolls, and comes back when scrolling to the top.
    public func installSearch(placeholder: String, collapsesWhileScrolling: Bool = true, onChange: @escaping (String) -> Void) {
        let updater = SearchUpdater(onChange: onChange)
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = updater
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = placeholder
        navigationItem.searchController = search
        // Visible at first; `viewDidAppear` enables collapsing (setting it now would start hidden).
        navigationItem.hidesSearchBarWhenScrolling = false
        collapsesSearchWhileScrolling = collapsesWhileScrolling
        definesPresentationContext = true
        searchUpdater = updater
    }
}

private final class SearchUpdater: NSObject, UISearchResultsUpdating {
    let onChange: (String) -> Void

    init(onChange: @escaping (String) -> Void) {
        self.onChange = onChange
    }

    func updateSearchResults(for searchController: UISearchController) {
        onChange(searchController.searchBar.text ?? "")
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
