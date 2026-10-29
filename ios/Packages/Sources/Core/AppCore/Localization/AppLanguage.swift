import Foundation
import os

/// Languages the app ships. The in-app choice (Settings → Language) wins over the device language.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case ukrainian = "uk"
    case english = "en"

    public var id: String { rawValue }

    public var locale: Locale { Locale(identifier: rawValue) }

    /// The language's own name, shown in the picker regardless of the current language.
    public var nativeName: String {
        switch self {
        case .ukrainian: "Українська"
        case .english: "English"
        }
    }

    /// First launch (ROADMAP D5): English if the device's preferred language is English, Ukrainian otherwise.
    public static func systemDefault(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard let first = preferredLanguages.first else { return .ukrainian }
        return Locale(identifier: first).language.languageCode?.identifier == "en" ? .english : .ukrainian
    }
}

public extension Notification.Name {
    /// Posted on the main thread after the in-app language changes. The UI rebuilds itself.
    static let appLanguageDidChange = Notification.Name("CoffeeMaster.appLanguageDidChange")
}

/// Stores the chosen language. Thread-safe; read by every localized lookup.
public final class LanguageSettings: Sendable {
    public static let shared = LanguageSettings()

    private static let key = "app.language"
    private let cached: OSAllocatedUnfairLock<AppLanguage?>
    // `UserDefaults` is documented as thread-safe but isn't marked `Sendable`.
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        cached = OSAllocatedUnfairLock(initialState: nil)
    }

    public var current: AppLanguage {
        cached.withLock { cached in
            if let cached { return cached }
            let stored = defaults.string(forKey: Self.key).flatMap(AppLanguage.init(rawValue:))
            let language = stored ?? .systemDefault()
            cached = language
            return language
        }
    }

    /// Persists the choice and notifies the UI (no-op if unchanged).
    public func set(_ language: AppLanguage) {
        let changed = cached.withLock { cached in
            guard cached != language else { return false }
            cached = language
            return true
        }
        guard changed else { return }
        defaults.set(language.rawValue, forKey: Self.key)
        Task { @MainActor in
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }
}
