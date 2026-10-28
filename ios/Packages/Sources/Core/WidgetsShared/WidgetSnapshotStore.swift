import Foundation
import WidgetKit
import AppCore

/// Reads / writes `WidgetSnapshot` in the shared App Group.
/// App: `save(_:)` after data changes. Widget TimelineProvider: `load()`.
public struct WidgetSnapshotStore: Sendable {
    private static let key = "widget.snapshot"
    private let appGroupID: String

    public init(appGroupID: String = AppConfiguration.appGroupID) {
        self.appGroupID = appGroupID
    }

    public func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public func save(_ snapshot: WidgetSnapshot) {
        guard let defaults else {
            Log.widgets.error("App Group \(appGroupID, privacy: .public) is not configured")
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(snapshot), forKey: Self.key)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.latestBrews)
        } catch {
            Log.widgets.error("Failed to encode widget snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
}
