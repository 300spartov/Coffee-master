import Domain

// Navigation intents emitted by the feature's view models; `ProfileFlow` in the app implements them.
public protocol ProfileRouting: AnyObject {
    func showEditProfile()
    /// The avatar picker (a sheet; it saves as you pick).
    func showAvatarPicker()
    /// Deleted brews (the journal's trash).
    func showTrash()
    func showSettings()
}

public protocol ProfileFormRouting: AnyObject {
    /// Saved, or cancelled (`saved` false).
    func profileFormDidFinish(saved: Bool)
}

public protocol AvatarPickerRouting: AnyObject {
    func avatarPickerDidFinish()
}
