import Foundation
import AppCore

/// String from this module's catalog in the in-app language (or `language`, for tests).
func tr(_ key: String.LocalizationValue, language: AppLanguage = LanguageSettings.shared.current) -> String {
    L10n.string(key, bundle: .module, language: language)
}
