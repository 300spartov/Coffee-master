import Foundation
import FactoryKit
import AppCore
import DataLayer
import DesignSystem
import WebImport

/// Imports a web app export (D2) and says how it went in a toast. Used by Settings → "Import from Web
/// App" and the Debug `-importWebJSON <path>` launch argument.
@MainActor
struct WebImportCoordinator {
    @Injected(\.webImportService) private var webImport
    @Injected(\.toasts) private var toasts

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
