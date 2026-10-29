import UIKit
import FactoryKit
import UniformTypeIdentifiers
import AppCore
import DataLayer
import DeepLinks
import DesignSystem
import Navigation
import SettingsFeature
import WebImport

/// Profile tab. For now it hosts Settings; the profile itself (stats, XP, achievements) comes in
/// ROADMAP Phase 4.
final class ProfileFlow: NSObject, Flow {
    private let module: SettingsModule
    private let router = StackRouter()
    @Injected(\.toasts) private var toasts
    @Injected(\.webImportService) private var webImport
    private let startBrew: () -> Void

    var rootViewController: UIViewController { router.navigationController }

    init(module: SettingsModule, startBrew: @escaping () -> Void) {
        self.module = module
        self.startBrew = startBrew
        super.init()
        router.navigationController.tabBarItem = UITabBarItem(
            title: tr("Profile"),
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
    }

    func start() {
        router.setRoot(module.makeSettings(router: self, title: tr("Profile")))
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
        case .about:
            router.push(module.makeAbout(), animated: false)
        case .designSystem:
            #if DEBUG
            router.push(makeDesignSystemGallery(), animated: false)
            #endif
        default:
            // `.achievements` lands on Profile until its screen arrives (ROADMAP 4.3).
            break
        }
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
