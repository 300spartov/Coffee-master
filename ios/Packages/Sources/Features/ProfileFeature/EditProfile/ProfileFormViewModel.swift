import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// Edit Profile (web: `ov-settings` → `saveProf`): name, city, category, experience.
@Observable
final class ProfileFormViewModel: AlertingViewModel {
    private(set) var state: LoadState = .loading
    var name = ""
    var location = ""
    var title = ""
    var experience = ""
    private(set) var isSaving = false
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
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        var edited = profile
        edited.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.title = title
        edited.experience = experience.trimmingCharacters(in: .whitespacesAndNewlines)
        if await attempt({ try await profiles.saveProfile(edited) }) {
            router?.profileFormDidFinish(saved: true)
        }
    }

    func cancel() {
        router?.profileFormDidFinish(saved: false)
    }
}
