import Foundation

/// Localized lookups in the **in-app** language.
///
/// Each module keeps its strings in its own `Resources/Localizable.xcstrings` and calls a
/// module-local `tr("…")` that forwards here with `Bundle.module`. Pinning both the bundle and the
/// locale makes every module show the same language, whatever the device language is.
public enum L10n {
    public static func string(
        _ key: String.LocalizationValue,
        bundle: Bundle,
        language: AppLanguage = LanguageSettings.shared.current
    ) -> String {
        String(localized: LocalizedStringResource(key, locale: language.locale, bundle: .atURL(bundle.bundleURL)))
    }
}
