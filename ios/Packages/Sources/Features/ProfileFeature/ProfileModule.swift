import UIKit
import Domain
import Navigation

/// Public entry point of the feature (ROADMAP 4.1): the Profile tab's root, Edit Profile and the
/// avatar picker. Settings and the trash come from their own modules (the flow pushes them).
public struct ProfileModule {
    public init() {}

    public func makeProfile(router: any ProfileRouting) -> UIViewController {
        HostingController(rootView: ProfileView(viewModel: ProfileViewModel(router: router)), title: tr("Profile"), largeTitleDisplayMode: .always)
    }

    /// Present it modally (it has a Cancel button).
    public func makeEditProfile(router: any ProfileFormRouting) -> UIViewController {
        let viewModel = ProfileFormViewModel(router: router)
        let controller = HostingController(rootView: ProfileFormView(viewModel: viewModel), title: tr("Edit Profile"))
        controller.setCancelButton { [weak viewModel] in viewModel?.cancel() }
        return controller
    }

    /// A sheet; Done closes it (picks are saved as they're made).
    public func makeAvatarPicker(router: any AvatarPickerRouting) -> UIViewController {
        let viewModel = AvatarPickerViewModel(router: router)
        let controller = HostingController(rootView: AvatarPickerView(viewModel: viewModel), title: tr("Avatar"))
        controller.setDoneButton(identifier: "avatar.done") { [weak viewModel] in viewModel?.done() }
        return controller
    }
}
