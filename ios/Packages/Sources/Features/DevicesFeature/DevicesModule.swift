import UIKit
import Domain
import Navigation

/// Public entry point of the feature. Builds screens and wires each ViewModel to its router.
/// Services are injected into ViewModels by Factory (`@Injected`). Views and ViewModels stay `internal`.
public struct DevicesModule {
    public init() {}

    public func makeCategories(router: any DeviceCategoriesRouting) -> UIViewController {
        let viewModel = DeviceCategoriesViewModel(router: router)
        let controller = HostingController(
            rootView: DeviceCategoriesView(viewModel: viewModel),
            title: tr("Devices"),
            largeTitleDisplayMode: .always
        )
        controller.view.accessibilityIdentifier = "devices.categories"
        return controller
    }

    /// One category: owned devices + catalog, with the system search bar and an "add" button.
    public func makeCatalog(type: DeviceType, router: any DeviceCatalogRouting) -> UIViewController {
        let viewModel = DeviceCatalogViewModel(type: type, router: router)
        let controller = HostingController(
            rootView: DeviceCatalogView(viewModel: viewModel),
            title: type.title,
            hidesBottomBarWhenPushed: true
        )
        controller.installSearch(placeholder: tr("Search devices")) { [weak viewModel] text in
            viewModel?.query = text
        }
        let addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapAdd() }
        )
        addItem.accessibilityLabel = tr("Add Device")
        addItem.accessibilityIdentifier = "devices.add"
        controller.navigationItem.rightBarButtonItem = addItem
        return controller
    }

    /// Sheet for a custom device; `type` preselects the category.
    public func makeAddDevice(type: DeviceType, router: any DeviceFormRouting) -> UIViewController {
        makeForm(mode: .add(type), title: tr("New Device"), router: router)
    }

    /// Sheet for renaming / recategorizing / removing a device you own.
    public func makeEditDevice(id: Device.ID, router: any DeviceFormRouting) -> UIViewController {
        makeForm(mode: .edit(id), title: tr("Edit Device"), router: router)
    }

    /// Filter packs with their remaining counts and an "add" button.
    public func makeFilterPacks(router: any FilterPacksRouting) -> UIViewController {
        let viewModel = FilterPacksViewModel(router: router)
        let controller = HostingController(
            rootView: FilterPacksView(viewModel: viewModel),
            title: tr("Filter packs"),
            hidesBottomBarWhenPushed: true
        )
        let addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.didTapAdd() }
        )
        addItem.accessibilityLabel = tr("Add Filter Pack")
        addItem.accessibilityIdentifier = "filters.add"
        controller.navigationItem.rightBarButtonItem = addItem
        return controller
    }

    public func makeAddFilterPack(router: any FilterPackFormRouting) -> UIViewController {
        makeFilterPackForm(mode: .add, title: tr("New Filter Pack"), router: router)
    }

    public func makeEditFilterPack(id: FilterPack.ID, router: any FilterPackFormRouting) -> UIViewController {
        makeFilterPackForm(mode: .edit(id), title: tr("Edit Filter Pack"), router: router)
    }

    private func makeFilterPackForm(mode: FilterPackFormViewModel.Mode, title: String, router: any FilterPackFormRouting) -> UIViewController {
        let viewModel = FilterPackFormViewModel(mode: mode, router: router)
        let controller = HostingController(rootView: FilterPackFormView(viewModel: viewModel), title: title)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.cancel() }
        )
        controller.isModalInPresentation = true
        return controller
    }

    private func makeForm(mode: DeviceFormViewModel.Mode, title: String, router: any DeviceFormRouting) -> UIViewController {
        let viewModel = DeviceFormViewModel(mode: mode, router: router)
        let controller = HostingController(rootView: DeviceFormView(viewModel: viewModel), title: title)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak viewModel] _ in viewModel?.cancel() }
        )
        // Don't lose a typed name to an accidental swipe (like the New Bean sheet); Cancel closes it.
        controller.isModalInPresentation = true
        return controller
    }
}
