import FactoryKit
import Foundation

public extension Container {
    /// User preferences (haptics, …). Tests can register one backed by an isolated suite.
    var preferences: Factory<AppPreferences> {
        self { AppPreferences() }.cached
    }

    /// "1.2.0 (42)" from the main bundle.
    var appVersion: Factory<String> {
        self {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
            return "\(version) (\(build))"
        }.cached
    }
}
