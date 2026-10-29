import UIKit
import Domain
import Navigation

/// Public entry point of the feature. Builds screens and wires each ViewModel to its router.
/// Services are injected into ViewModels by Factory (`@Injected`). Views and ViewModels stay `internal`.
@MainActor
public struct BrewsModule {
    public init() {}

    public func makeBrewList(router: any BrewListRouting) -> UIViewController {
        let viewModel = BrewListViewModel(router: router)
        let controller = HostingController(
            rootView: BrewListView(viewModel: viewModel),
            title: tr("Brews"),
            largeTitleDisplayMode: .always
        )
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapAdd() }
        )
        return controller
    }

    public func makeBrewDetail(id: Brew.ID, router: any BrewDetailRouting) -> UIViewController {
        let viewModel = BrewDetailViewModel(brewID: id, router: router)
        return HostingController(
            rootView: BrewDetailView(viewModel: viewModel),
            hidesBottomBarWhenPushed: true
        )
    }

    public func makeNewBrew(router: any NewBrewRouting) -> UIViewController {
        let viewModel = NewBrewViewModel(router: router)
        let controller = HostingController(
            rootView: NewBrewView(viewModel: viewModel),
            title: tr("New Brew")
        )
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.cancel() }
        )
        return controller
    }
}
