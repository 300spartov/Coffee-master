import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Edit Profile (web: `ov-settings` → `saveProf`): name, city, category, experience.
@Observable
final class ProfileFormViewModel: SavingViewModel {
    private(set) var state: LoadState = .loading
    var name = ""
    var location = ""
    var title = ""
    var experience = ""
    var isSaving = false
    var alertMessage: String?

    @ObservationIgnored private var profile = UserProfile()
    @ObservationIgnored @Injected(\.profileRepository) private var profiles
    @ObservationIgnored private weak var router: (any ProfileFormRouting)?

    init(router: any ProfileFormRouting) {
        self.router = router
    }

    func load() async {
        guard state == .loading else { return }
        do {
            profile = try await profiles.profile()
            (name, location, title, experience) = (profile.name, profile.location, profile.title, profile.experience)
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// The presets, plus an imported title that isn't one of them (so it isn't lost).
    var titles: [String] {
        UserProfile.titlePresets + (title.isEmpty || UserProfile.titlePresets.contains(title) ? [] : [title])
    }

    func save() async {
        await whileSaving {
            var edited = profile
            edited.name = name.trimmed
            edited.location = location.trimmed
            edited.title = title
            edited.experience = experience.trimmed
            if await attempt({ try await profiles.saveProfile(edited) }) {
                router?.profileFormDidFinish(saved: true)
            }
        }
    }

    func cancel() {
        router?.profileFormDidFinish(saved: false)
    }
}
