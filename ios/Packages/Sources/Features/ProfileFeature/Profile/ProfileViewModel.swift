import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// The Profile tab's root (web: `renderProfile`): who you are and what you have. XP, achievements and
/// the streak come with ROADMAP 4.2–4.4.
@Observable
final class ProfileViewModel {
    /// The counts under the profile card.
    struct Counts: Equatable {
        var brews = 0
        var beans = 0
        var devices = 0
    }

    private(set) var profile = UserProfile()
    private(set) var counts = Counts()

    @ObservationIgnored @Injected(\.profileRepository) private var profiles
    @ObservationIgnored @Injected(\.brewRepository) private var brews
    @ObservationIgnored @Injected(\.beanRepository) private var beans
    @ObservationIgnored @Injected(\.deviceRepository) private var devices
    @ObservationIgnored private weak var router: (any ProfileRouting)?

    init(router: any ProfileRouting) {
        self.router = router
    }

    /// Bound to the view via `.task` (so the counts refresh each time it appears); then follows the
    /// profile's changes (edits, the avatar).
    func start() async {
        await profiles.observe { await self.load() }
    }

    func load() async {
        profile = (try? await profiles.profile()) ?? UserProfile()
        counts = Counts(
            brews: (try? await brews.fetchAll().count) ?? 0,
            beans: (try? await beans.fetchAll().count) ?? 0,
            devices: (try? await devices.fetchAll().count) ?? 0
        )
    }

    /// "Бариста · 2 роки" (the category translated), or empty.
    var subtitle: String {
        [ProfileTitle.displayName(profile.title), profile.experience].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    func didTapAvatar() { router?.showAvatarPicker() }
    func didTapEdit() { router?.showEditProfile() }
    func didTapTrash() { router?.showTrash() }
    func didTapSettings() { router?.showSettings() }
}

/// The web app's categories (stored as it stores them), shown translated.
enum ProfileTitle {
    static func displayName(_ stored: String) -> String {
        switch stored {
        case "Новичок": tr("Beginner")
        case "Любитель кофе": tr("Coffee lover")
        case "Кофейный сектант": tr("Coffee devotee")
        case "Бариста": tr("Barista")
        case "Профессионал": tr("Professional")
        default: stored
        }
    }
}
