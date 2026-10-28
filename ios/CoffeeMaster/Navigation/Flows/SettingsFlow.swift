import UIKit
import Factory
import UniformTypeIdentifiers
import AppCore
import DataLayer
import DeepLinks
import DesignSystem
import Navigation
import SettingsFeature
import WebImport

/// Settings tab. Shows how one flow reaches another feature: by emitting a deep link
/// that `AppRouter` routes, never by importing the other feature.
@MainActor
final class SettingsFlow: NSObject, Flow {
    private let module: SettingsModule
    private let router = StackRouter()
    @Injected(\.toasts) private var toasts
    @Injected(\.webImportService) private var webImport
    private let openDeepLink: (DeepLink) -> Void

    var rootViewController: UIViewController { router.navigationController }

    init(module: SettingsModule, openDeepLink: @escaping (DeepLink) -> Void) {
        self.module = module
        self.openDeepLink = openDeepLink
        super.init()
        router.navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Settings"),
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
    }

    func start() {
        router.setRoot(module.makeSettings(router: self))
    }

    func canHandle(_ deepLink: DeepLink) -> Bool {
        switch deepLink {
        case .settings, .about: true
        case .brews, .brewDetail, .newBrew: false
        }
    }

    func handle(_ deepLink: DeepLink) {
        router.popToRoot(animated: false)
        if deepLink == .about {
            router.push(module.makeAbout(), animated: false)
        }
    }
}

extension SettingsFlow: SettingsRouting {
    func showAbout() {
        router.push(module.makeAbout())
    }

    func showNewBrew() {
        openDeepLink(.newBrew)
    }

    func showWebImport() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        router.present(picker)
    }
}

extension SettingsFlow: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        Task { await importWebData(from: url) }
    }

    /// Also used by the Debug `-importWebJSON <path>` launch argument.
    func importWebData(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let summary = try await webImport.importJSON(data)
            toasts.show(Self.toast(for: summary))
        } catch let error as WebImportError {
            Log.data.error("Web import rejected: \(String(describing: error), privacy: .public)")
            toasts.show(Toast(String(localized: "This file isn't a Coffee Master export."), style: .error))
        } catch {
            Log.data.error("Web import failed: \(error.localizedDescription, privacy: .public)")
            toasts.show(Toast(String(localized: "Import failed. Please try again."), style: .error))
        }
    }

    private static func toast(for summary: WebImportSummary) -> Toast {
        guard summary.changedCount > 0 else {
            return Toast(String(localized: "Everything is already imported."), style: .info)
        }
        let brews = summary.brews.inserted + summary.brews.updated
        let beans = summary.beans.inserted + summary.beans.updated
        return Toast(String(localized: "Imported \(brews) brews and \(beans) beans"), style: .success)
    }
}
