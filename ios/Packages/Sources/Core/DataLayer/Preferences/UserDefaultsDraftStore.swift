import Foundation
import Domain

/// `DraftStore` in `UserDefaults`.
public final class UserDefaultsDraftStore: DraftStore {
    // `UserDefaults` is documented as thread-safe but isn't marked `Sendable`.
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(for key: String) -> Data? { defaults.data(forKey: key) }

    public func setData(_ data: Data?, for key: String) {
        if let data { defaults.set(data, forKey: key) } else { defaults.removeObject(forKey: key) }
    }
}
