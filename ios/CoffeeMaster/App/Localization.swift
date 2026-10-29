import Foundation
import AppCore

/// String from the app's catalog (`Localizable.xcstrings`) in the in-app language.
func tr(_ key: String.LocalizationValue) -> String {
    L10n.string(key, bundle: .main)
}
