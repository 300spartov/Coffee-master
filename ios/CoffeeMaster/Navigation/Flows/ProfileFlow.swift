import UIKit
import FactoryKit
import UniformTypeIdentifiers
import DeepLinks
import DesignSystem
import Navigation
import SettingsFeature
import ProfileFeature
import JournalFeature

/// Profile tab: the profile (ROADMAP 4.1) → Edit Profile and the avatar picker (sheets), Deleted Brews
/// and Settings (pushes). Stats, XP and achievements come with the rest of Phase 4.
final class ProfileFlow: Flow {
    private let profileModule: ProfileModule
    private let module: SettingsModule
    /// The journal's trash lives under Profile → Data, like the web app.
    private let journalModule: JournalModule
    private let router = StackRouter()
    @Injected(\.toasts) private var toasts

    var rootViewController: UIViewController { router.navigationController }

    /// Edit Profile or the avatar picker.
    private let modal = ModalSlot()

    init(profileModule: ProfileModule, module: SettingsModule, journalModule: JournalModule) {
        self.profileModule = profileModule
        self.module = module
        self.journalModule = journalModule
        router.navigationController.tabBarItem = UITabBarItem(title: tr("Profile"), systemImage: "person.crop.circle")
    }

    func start() {
        router.setRoot(profileModule.makeProfile(router: self))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        switch deepLink {
        case .profile, .achievements, .settings, .about, .designSystem: true
        default: false
        }
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
        switch deepLink {
        case .settings:
            router.push(makeSettings(), animated: false)
        case .about:
            router.push(makeSettings(), animated: false)
            router.push(module.makeAbout(), animated: false)
        case .designSystem:
            #if DEBUG
            router.push(makeSettings(), animated: false)
            router.push(makeDesignSystemGallery(), animated: false)
            #endif
        default:
            // `.achievements` lands on Profile until its screen arrives (ROADMAP 4.3).
            break
        }
    }
}

extension ProfileFlow: ProfileRouting {
    func showEditProfile() {
        modal.presentSheet(profileModule.makeEditProfile(router: self), over: router)
    }

    func showAvatarPicker() {
        modal.presentSheet(profileModule.makeAvatarPicker(router: self), over: router, size: .resizable)
    }

    func showTrash() {
        router.push(journalModule.makeTrash())
    }

    func showSettings() {
        router.push(makeSettings())
    }

    private func makeSettings() -> UIViewController {
        module.makeSettings(router: self)
    }
}

extension ProfileFlow: ProfileFormRouting, AvatarPickerRouting {
    func profileFormDidFinish(saved: Bool) {
        modal.close()
        if saved { toasts.show(tr("Profile saved"), style: .success) }
    }

    func avatarPickerDidFinish() {
        modal.close()
    }
}

extension ProfileFlow: SettingsRouting {
    func showAbout() {
        router.push(module.makeAbout())
    }

    func showDesignSystem() {
        #if DEBUG
        router.push(makeDesignSystemGallery())
        #endif
    }

    #if DEBUG
    private func makeDesignSystemGallery() -> UIViewController {
        HostingController(
            rootView: DesignSystemGallery { [weak self] toast in self?.toasts.show(toast) },
            title: "Design System",
            hidesBottomBarWhenPushed: true
        )
    }
    #endif

    func showWebImport() {
        DocumentPicker.present(over: router, types: [.json]) { url in
            Task { await WebImportCoordinator().importWebData(from: url) }
        }
    }
}
