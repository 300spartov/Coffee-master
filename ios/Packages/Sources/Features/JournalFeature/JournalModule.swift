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
        // "+" logs a brew after the fact; starting one is the app-wide Brew button on the right.
        let log = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapLog() })
        log.accessibilityLabel = tr("Log a Brew")
        log.accessibilityIdentifier = "journal.log"
        controller.navigationItem.leftBarButtonItem = log
        controller.view.accessibilityIdentifier = "journal.list"
        return controller
    }

    /// Log a brew after the fact (present it modally; it has a Cancel button).
    public func makeLogBrew(router: any BrewFormRouting) -> UIViewController {
        let viewModel = BrewFormViewModel(mode: .add, router: router)
        let controller = HostingController(rootView: BrewFormView(viewModel: viewModel), title: tr("Log a Brew"))
        controller.setCancelButton { [weak viewModel] in viewModel?.cancel() }
        return controller
    }

    /// A brew to look at and edit (push it); deleting it is there too.
    public func makeBrewForm(id: Brew.ID, router: any BrewFormRouting) -> UIViewController {
        let viewModel = BrewFormViewModel(mode: .edit(id), router: router)
        return HostingController(
            rootView: BrewFormView(viewModel: viewModel),
            title: tr("Edit Brew"),
            hidesBottomBarWhenPushed: true
        )
    }
}
