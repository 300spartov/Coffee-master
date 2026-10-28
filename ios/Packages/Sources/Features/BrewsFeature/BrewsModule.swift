import UIKit
import Domain
import Navigation

/// Public entry point of the feature. Builds screens and wires each ViewModel to its dependencies
/// and router. Views and ViewModels stay `internal`.
@MainActor
public struct BrewsModule {
    public struct Dependencies {
        public let repository: any BrewRepository
        public let brewTimer: any BrewTimerService

        public init(repository: any BrewRepository, brewTimer: any BrewTimerService) {
            self.repository = repository
            self.brewTimer = brewTimer
        }
    }

    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func makeBrewList(router: any BrewListRouting) -> UIViewController {
        let viewModel = BrewListViewModel(repository: dependencies.repository, router: router)
        let controller = HostingController(
            rootView: BrewListView(viewModel: viewModel),
            title: String(localized: "Brews"),
            largeTitleDisplayMode: .always
        )
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapAdd() }
        )
        return controller
    }

    public func makeBrewDetail(id: Brew.ID, router: any BrewDetailRouting) -> UIViewController {
        let viewModel = BrewDetailViewModel(
            brewID: id,
            repository: dependencies.repository,
            brewTimer: dependencies.brewTimer,
            router: router
        )
        return HostingController(
            rootView: BrewDetailView(viewModel: viewModel),
            hidesBottomBarWhenPushed: true
        )
    }

    public func makeNewBrew(router: any NewBrewRouting) -> UIViewController {
        let viewModel = NewBrewViewModel(repository: dependencies.repository, router: router)
        let controller = HostingController(
            rootView: NewBrewView(viewModel: viewModel),
            title: String(localized: "New Brew")
        )
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.cancel() }
        )
        return controller
    }
}
