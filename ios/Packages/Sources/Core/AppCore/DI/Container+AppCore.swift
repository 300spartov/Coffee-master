import FactoryKit
import Foundation

public extension Container {
    /// Key-value settings storage. Tests can register an isolated suite.
    var userDefaults: Factory<UserDefaults> {
        self { .standard }.cached
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
