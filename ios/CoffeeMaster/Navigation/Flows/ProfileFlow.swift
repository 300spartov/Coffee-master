import UIKit
import FactoryKit
import UniformTypeIdentifiers
import AppCore
import DataLayer
import DeepLinks
import DesignSystem
import Navigation
import SettingsFeature
import ProfileFeature
import JournalFeature
import WebImport

/// Profile tab: the profile (ROADMAP 4.1) → Edit Profile and the avatar picker (sheets), Deleted Brews
/// and Settings (pushes). Stats, XP and achievements come with the rest of Phase 4.
final class ProfileFlow: NSObject, Flow {
    private let profileModule: ProfileModule
    private let module: SettingsModule
    /// The journal's trash lives under Profile → Data, like the web app.
    private let journalModule: JournalModule
    private let router = StackRouter()
    @Injected(\.toasts) private var toasts
    @Injected(\.webImportService) private var webImport
    private let startBrew: () -> Void

    var rootViewController: UIViewController { router.navigationController }

    /// Edit Profile or the avatar picker.
    private let modal = ModalSlot()

    init(profileModule: ProfileModule, module: SettingsModule, journalModule: JournalModule, startBrew: @escaping () -> Void) {
        self.profileModule = profileModule
        self.module = module
        self.journalModule = journalModule
        self.startBrew = startBrew
        super.init()
        router.navigationController.tabBarItem = UITabBarItem(
            title: tr("Profile"),
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
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
        modal.present {
            router.presentStack(root: profileModule.makeEditProfile(router: self)) { sheet in
                sheet.detents = [.large()]
            }
        }
    }

    func showAvatarPicker() {
        modal.present {
            router.presentStack(root: profileModule.makeAvatarPicker(router: self)) { sheet in
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
    }

    func showTrash() {
        router.push(journalModule.makeTrash())
    }

    func showSettings() {
        router.push(makeSettings())
    }

    private func makeSettings() -> UIViewController {
        module.makeSettings(router: self, title: tr("Settings"))
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

    func showNewBrew() {
        startBrew()
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
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        router.present(picker)
    }
}

extension ProfileFlow: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        Task { await importWebData(from: url) }
    }

    /// Also used by the Debug `-importWebJSON <path>` launch argument.
    func importWebData(from url: URL) async {
        do {
            toasts.show(Self.toast(for: try await webImport.importJSON(contentsOf: url)))
        } catch let error as WebImportError {
            Log.data.error("Web import rejected: \(String(describing: error), privacy: .public)")
            toasts.show(tr("This file isn't a Coffee Master export."), style: .error)
        } catch {
            Log.data.error("Web import failed: \(error.localizedDescription, privacy: .public)")
            toasts.show(tr("Import failed. Please try again."), style: .error)
        }
    }

    private static func toast(for summary: WebImportSummary) -> Toast {
        guard summary.changedCount > 0 else {
            return Toast(tr("Everything is already imported."), style: .info)
        }
        let brews = summary.brews.inserted + summary.brews.updated
        let beans = summary.beans.inserted + summary.beans.updated
        return Toast(tr("Imported — brews: \(brews), beans: \(beans)"), style: .success)
    }
}
