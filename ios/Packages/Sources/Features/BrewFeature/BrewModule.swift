import UIKit
import Domain
import Navigation

/// Public entry point of the brew wizard (ROADMAP Phase 2). Builds screens and wires each ViewModel
/// to its router. Views and ViewModels stay `internal`.
public struct BrewModule {
    public init() {}

    /// Step 1, the root of the brew flow: Alternative or Espresso.
    public func makeMethodGroups(router: any MethodPickRouting) -> UIViewController {
        let viewModel = MethodPickViewModel(router: router)
        let controller = HostingController(rootView: MethodGroupsView(viewModel: viewModel), title: tr("New Brew"))
        controller.setCancelButton { [weak viewModel] in viewModel?.cancel() }
        controller.view.accessibilityIdentifier = "brew.methodGroups"
        return controller
    }

    /// Step 2 (push it): the methods of `group`.
    public func makeMethods(in group: MethodGroup, router: any MethodPickRouting) -> UIViewController {
        let viewModel = MethodPickViewModel(group: group, router: router)
        return HostingController(rootView: MethodGridView(viewModel: viewModel), title: group.title)
    }
}
