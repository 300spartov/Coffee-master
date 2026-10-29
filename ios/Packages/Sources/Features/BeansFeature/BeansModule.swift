import UIKit
import Domain
import Navigation

/// Public entry point of the feature. Builds screens and wires each ViewModel to its router.
/// Services are injected into ViewModels by Factory (`@Injected`). Views and ViewModels stay `internal`.
public struct BeansModule {
    public init() {}

    public func makeBeanList(router: any BeanListRouting) -> UIViewController {
        let viewModel = BeanListViewModel(router: router)
        let controller = HostingController(
            rootView: BeanListView(viewModel: viewModel),
            title: tr("Beans"),
            largeTitleDisplayMode: .always
        )
        let addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapAdd() }
        )
        addItem.accessibilityLabel = tr("Add Bean")
        addItem.accessibilityIdentifier = "beans.add"
        controller.navigationItem.rightBarButtonItem = addItem
        controller.view.accessibilityIdentifier = "beans.list"
        return controller
    }

    /// Empty form for a new bag; present it modally (it has a Cancel button).
    public func makeAddBean(router: any BeanFormRouting) -> UIViewController {
        let viewModel = BeanFormViewModel(mode: .add, router: router)
        let controller = HostingController(rootView: BeanFormView(viewModel: viewModel), title: tr("New Bean"))
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.cancel() }
        )
        // Don't lose typed details to an accidental swipe.
        controller.isModalInPresentation = true
        return controller
    }

    /// Edit form for an existing bag (push it).
    public func makeEditBean(id: Bean.ID, router: any BeanFormRouting) -> UIViewController {
        let viewModel = BeanFormViewModel(mode: .edit(id), router: router)
        return HostingController(
            rootView: BeanFormView(viewModel: viewModel),
            title: tr("Edit Bean"),
            hidesBottomBarWhenPushed: true
        )
    }
}
