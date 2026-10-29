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
}
