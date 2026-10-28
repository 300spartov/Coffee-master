import ActivityKit
import Foundation
import AppCore
import Domain

/// ActivityKit-backed `BrewTimerService`.
/// The activity is requested even without a Widget Extension, but nothing is rendered until one
/// declaring `ActivityConfiguration(for: BrewTimerAttributes.self)` is added.
public actor LiveActivityBrewTimerService: BrewTimerService {
    public enum TimerError: LocalizedError {
        case activitiesDisabled

        public var errorDescription: String? {
            "Live Activities are turned off for this app in Settings."
        }
    }

    public init() {}

    public func start(for brew: Brew) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw TimerError.activitiesDisabled
        }
        await stop()

        let attributes = BrewTimerAttributes(
            brewID: brew.id,
            methodTitle: brew.method.title,
            beanName: brew.beanName
        )
        let state = BrewTimerAttributes.ContentState(startedAt: .now, targetDuration: brew.brewTime)
        let activity = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
        Log.widgets.info("Started live activity \(activity.id, privacy: .public)")
    }

    public func stop() async {
        for activity in Activity<BrewTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
