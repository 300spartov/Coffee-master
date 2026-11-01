import ActivityKit
import Foundation
import Domain
import DeepLinks

/// Live Activity model for a running brew. Shared by the app (starts, updates and ends it) and the
/// Widget Extension (renders it with `ActivityConfiguration(for: BrewTimerAttributes.self)`).
public struct BrewTimerAttributes: ActivityAttributes {
    public typealias ContentState = BrewTimerStatus

    public init() {}

    /// Tap target: the app reopens at the brew in progress (`brew/new` resumes it).
    public var deepLinkURL: URL { DeepLink.newBrew.url }
}
