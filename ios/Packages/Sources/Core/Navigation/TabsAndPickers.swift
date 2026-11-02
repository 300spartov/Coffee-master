import UIKit
import UniformTypeIdentifiers

public extension UITabBarItem {
    /// A tab with an SF Symbol, filled when selected (`leaf` → `leaf.fill`).
    convenience init(title: String, systemImage: String) {
        self.init(title: title, image: UIImage(systemName: systemImage), selectedImage: UIImage(systemName: systemImage + ".fill"))
    }
}

/// Picks a file (a copy) with the system document picker and hands its URL to `onPick`.
public final class DocumentPicker: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void
    /// Keeps the delegate alive while the picker is open (UIKit holds it weakly).
    private var retainedWhileOpen: DocumentPicker?

    private init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
    }

    public static func present(over router: StackRouter, types: [UTType], onPick: @escaping (URL) -> Void) {
        let delegate = DocumentPicker(onPick: onPick)
        delegate.retainedWhileOpen = delegate
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = delegate
        router.present(picker)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first { onPick(url) }
        retainedWhileOpen = nil
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        retainedWhileOpen = nil
    }
}
