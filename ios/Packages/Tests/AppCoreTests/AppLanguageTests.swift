import Foundation
import Testing
@testable import AppCore

struct AppLanguageTests {
    @Test(arguments: [
        (["en-US", "uk-UA"], AppLanguage.english),
        (["en-GB"], .english),
        (["uk-UA", "en-US"], .ukrainian),
        (["ru-UA"], .ukrainian),
        (["de-DE", "en-US"], .ukrainian),
        ([], .ukrainian),
    ])
    func systemDefault(_ preferred: [String], expected: AppLanguage) {
        #expect(AppLanguage.systemDefault(preferredLanguages: preferred) == expected)
    }

    @Test func nativeNamesDontDependOnLanguage() {
        #expect(AppLanguage.ukrainian.nativeName == "Українська")
        #expect(AppLanguage.english.nativeName == "English")
    }
}

struct LanguageSettingsTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test func persistsChoice() {
        let defaults = makeDefaults()
        LanguageSettings(defaults: defaults).set(.english)

        #expect(LanguageSettings(defaults: defaults).current == .english)
        #expect(defaults.string(forKey: "app.language") == "en")
    }

    @Test func fallsBackToSystemDefaultForUnknownValue() {
        let defaults = makeDefaults()
        defaults.set("de", forKey: "app.language")

        #expect(LanguageSettings(defaults: defaults).current == AppLanguage.systemDefault())
    }

    @MainActor
    @Test func postsChangeNotification() async throws {
        let settings = LanguageSettings(defaults: makeDefaults())
        let initial = settings.current
        let other: AppLanguage = initial == .english ? .ukrainian : .english
        let notifications = NotificationCenter.default.notifications(named: .appLanguageDidChange)

        settings.set(initial) // unchanged: no notification
        settings.set(other)

        let iterator = notifications.makeAsyncIterator()
        _ = await iterator.next()
        #expect(settings.current == other)
    }

    @Test func resolvesWithExplicitLanguage() {
        // Foundation has its own strings for neither key; an unknown key falls back to itself.
        #expect(L10n.string("Not a key", bundle: .main, language: .ukrainian) == "Not a key")
    }
}
