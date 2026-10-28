import ActivityKit
import Foundation
import DeepLinks

/// Live Activity model for a running brew timer.
/// Shared by the app (starts / ends the activity) and the Widget Extension (renders it with
/// `ActivityConfiguration(for: BrewTimerAttributes.self)`).
public struct BrewTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var startedAt: Date
        public var targetDuration: TimeInterval

        public init(startedAt: Date, targetDuration: TimeInterval) {
            self.startedAt = startedAt
            self.targetDuration = targetDuration
        }

        /// Use with `Text(timerInterval:)` / `ProgressView(timerInterval:)`.
        public var timerRange: ClosedRange<Date> {
            startedAt...startedAt.addingTimeInterval(targetDuration)
        }
    }

    public let brewID: String
    public let methodTitle: String
    public let beanName: String

    public init(brewID: String, methodTitle: String, beanName: String) {
        self.brewID = brewID
        self.methodTitle = methodTitle
        self.beanName = beanName
    }

    /// Tap target for the Lock Screen / Dynamic Island presentation (`.widgetURL(...)`).
    public var deepLinkURL: URL {
        DeepLink.brewDetail(id: brewID).url
    }
}
