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
        controller.installSearch(placeholder: tr("Search brews")) { [weak viewModel] text in
            viewModel?.filter.text = text
        }
        controller.setFilterButton(accessibilityLabel: tr("Filters"), identifier: "journal.filters") { [weak viewModel] in
            viewModel?.didTapFilters()
        }
        viewModel.onHasFiltersChange = { [weak controller] isOn in controller?.setFilterButton(isOn: isOn) }
        // "+" logs a brew after the fact; the app puts its Brew button to the right of it.
        controller.setAddButton(accessibilityLabel: tr("Log a Brew"), identifier: "journal.log") { [weak viewModel] in viewModel?.didTapLog() }
        // iOS 26: the compare bar rides on the tab bar (its bottom accessory) while the feed is visible.
        if #available(iOS 26, *) {
            viewModel.onShowsCompareBarChange = { [weak controller, weak viewModel] shows in
                guard let controller, let viewModel else { return }
                controller.setTabAccessory(shows ? CompareBar(viewModel: viewModel, isTabAccessory: true) : nil)
            }
        }
        controller.view.accessibilityIdentifier = "journal.list"
        return controller
    }

    /// The feed's filter sheet (present it as a resizable sheet; it has Done).
    public func makeFilters(_ filters: FeedFilters, router: any FeedFiltersRouting) -> UIViewController {
        let controller = HostingController(rootView: FeedFiltersView(viewModel: filters.feed), title: tr("Filters"))
        controller.setDoneButton(identifier: "filters.done") { [weak router] in router?.feedFiltersDidFinish() }
        return controller
    }

    /// Log a brew after the fact (present it modally; it has a Cancel button).
    public func makeLogBrew(router: any BrewFormRouting) -> UIViewController {
        let viewModel = BrewFormViewModel(mode: .add, router: router)
        let controller = HostingController(rootView: BrewFormView(viewModel: viewModel), title: tr("Log a Brew"))
        controller.setCancelButton { [weak viewModel] in viewModel?.cancel() }
        return controller
    }

    /// Deleted brews: restore or delete for good (push it; Profile opens it, like the web app).
    public func makeTrash() -> UIViewController {
        HostingController(rootView: TrashView(viewModel: TrashViewModel()), title: tr("Deleted Brews"), hidesBottomBarWhenPushed: true)
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
