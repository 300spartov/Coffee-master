import ActivityKit
import Foundation
import AppCore
import Domain

/// ActivityKit-backed `BrewTimerService`: one activity per brew, updated as the brew changes.
public actor LiveActivityBrewTimerService: BrewTimerService {
    public init() {}

    public func show(_ status: BrewTimerStatus) async {
        let content = ActivityContent(state: status, staleDate: nil)
        if let activity = Activity<BrewTimerAttributes>.activities.first {
            await activity.update(content)
            return
        }
        // Turned off in Settings: the brew goes on without it.
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            let activity = try Activity.request(attributes: BrewTimerAttributes(), content: content, pushType: nil)
            Log.widgets.info("Started live activity \(activity.id, privacy: .public)")
        } catch {
            Log.widgets.error("Couldn't start live activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func end() async {
        for activity in Activity<BrewTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
