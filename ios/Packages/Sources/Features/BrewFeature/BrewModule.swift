import UIKit
import Foundation
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

    /// Step 3 (push it) for alternative methods: gear and recipe.
    public func makeSetup(method: BrewMethod, router: any BrewSetupRouting) -> UIViewController {
        let viewModel = BrewSetupViewModel(method: method, router: router)
        return HostingController(rootView: BrewSetupView(viewModel: viewModel), title: method.rawValue)
    }

    /// Step 4 (it replaces the setup) for pour-over: the brew timer. Back is the screen's own, so a
    /// started brew isn't lost by accident.
    public func makeActiveBrew(setup: BrewSetup, router: any ActiveBrewRouting) -> UIViewController {
        let viewModel = ActiveBrewViewModel(setup: setup, router: router)
        let controller = HostingController(rootView: ActiveBrewView(viewModel: viewModel), title: setup.method.rawValue)
        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapBack() }
        )
        back.accessibilityLabel = tr("Back")
        back.accessibilityIdentifier = "active.back"
        controller.navigationItem.leftBarButtonItem = back
        return controller
    }

    /// Picker sheet for a setup row, with "+" to add a new item.
    public func makeGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, router: any GearPickerRouting) -> UIViewController {
        let viewModel = GearPickerViewModel(kind: kind, method: method, selectedID: selectedID, router: router)
        let controller = HostingController(rootView: GearPickerView(viewModel: viewModel), title: viewModel.title)
        controller.setAddButton(accessibilityLabel: tr("Add"), identifier: "picker.add") { [weak viewModel] in
            viewModel?.didTapAdd()
        }
        return controller
    }
}
