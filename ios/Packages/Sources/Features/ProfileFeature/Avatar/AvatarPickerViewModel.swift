import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// The avatar picker (web: `av-picker`): a photo from the library, or an emoji (or the name's letter)
/// on a background color, saved as you pick.
@Observable
final class AvatarPickerViewModel: AlertingViewModel {
    private(set) var profile = UserProfile()
    var alertMessage: String?

    @ObservationIgnored private var customColorSave: Task<Void, Never>?
    @ObservationIgnored @Injected(\.profileRepository) private var profiles
    @ObservationIgnored private weak var router: (any AvatarPickerRouting)?

    init(router: any AvatarPickerRouting) {
        self.router = router
    }

    func load() async {
        profile = (try? await profiles.profile()) ?? UserProfile()
    }

    /// `nil`: the name's first letter. Replaces a photo.
    func pick(emoji: String?) async {
        await update { $0.emoji = emoji; $0.photo = nil }
    }

    /// A library photo, kept as a small centered square (it isn't saved if it can't be read).
    func pick(photo data: Data) async {
        guard let photo = AvatarView.photo(from: data) else {
            alertMessage = tr("This photo can't be used.")
            return
        }
        await update { $0.photo = photo }
    }

    func removePhoto() async {
        await update { $0.photo = nil }
    }

    func pick(color: String) async {
        customColorSave?.cancel()
        await update { $0.colorHex = color }
    }

    /// A color from the system picker: shown right away, saved once it stops changing (the picker
    /// reports every step while you drag).
    func pickCustom(color: String) {
        profile.avatar.colorHex = color
        customColorSave?.cancel()
        customColorSave = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await pick(color: color)
        }
    }

    /// A color that isn't one of the presets.
    var hasCustomColor: Bool {
        profile.avatar.colorHex.map { !Avatar.colorPresets.contains($0) } ?? false
    }

    func done() {
        router?.avatarPickerDidFinish()
    }

    private func update(_ change: (inout Avatar) -> Void) async {
        var edited = profile
        change(&edited.avatar)
        profile = edited
        await attempt { try await profiles.saveProfile(edited) }
    }
}
