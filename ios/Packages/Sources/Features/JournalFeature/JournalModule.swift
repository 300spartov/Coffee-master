import UIKit
import Domain
import Navigation

/// Public entry point of the feature. Builds screens and wires each ViewModel to its router.
/// Services are injected into ViewModels by Factory (`@Injected`). Views and ViewModels stay `internal`.
public struct JournalModule {
    public init() {}

    /// The Journal tab's root: the feed.
    public func makeFeed(router: any FeedRouting) -> UIViewController {
        let viewModel = FeedViewModel(router: router)
        let controller = HostingController(
            rootView: FeedView(viewModel: viewModel),
            title: tr("Journal"),
            largeTitleDisplayMode: .always
        )
        // No "+" here: starting a brew is the app-wide Brew button in the top bar.
        controller.view.accessibilityIdentifier = "journal.list"
        return controller
    }

    public func makeBrewDetail(id: Brew.ID, router: any BrewDetailRouting) -> UIViewController {
        let viewModel = BrewDetailViewModel(brewID: id, router: router)
        return HostingController(
            rootView: BrewDetailView(viewModel: viewModel),
            hidesBottomBarWhenPushed: true
        )
    }
}
