#if DEBUG
/// No-op router for SwiftUI previews. Retained by `shared` because view models hold routers weakly.
final class PreviewRouter: ProfileRouting, ProfileFormRouting, AvatarPickerRouting {
    static let shared = PreviewRouter()

    func showEditProfile() {}
    func showAvatarPicker() {}
    func showTrash() {}
    func showSettings() {}
    func profileFormDidFinish(saved: Bool) {}
    func avatarPickerDidFinish() {}
}
#endif
