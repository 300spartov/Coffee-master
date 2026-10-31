import UIKit
import Domain
import Navigation

/// Public entry point of the feature. Builds screens and wires each ViewModel to its router.
/// Services are injected into ViewModels by Factory (`@Injected`). Views and ViewModels stay `internal`.
public struct BrewsModule {
    public init() {}

    public func makeBrewList(router: any BrewListRouting) -> UIViewController {
        let viewModel = BrewListViewModel(router: router)
        let controller = HostingController(
            rootView: BrewListView(viewModel: viewModel),
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

    /// The template brew form, pushed by the brew wizard after the method pick until the wizard's
    /// own setup and rating steps (ROADMAP 2.2–2.7) replace it.
    public func makeNewBrew(setup: BrewSetup, steps: [BrewStep] = [], totalTime: TimeInterval? = nil, router: any NewBrewRouting) -> UIViewController {
        let viewModel = NewBrewViewModel(setup: setup, steps: steps, totalTime: totalTime, router: router)
        return HostingController(rootView: NewBrewView(viewModel: viewModel), title: setup.method.rawValue)
    }
}
