import ActivityKit
import SwiftUI
import WidgetKit
import WidgetsShared

/// The Widget Extension: the brew timer's Live Activity (ROADMAP 2.4). Views live in `WidgetsShared`.
@main
struct CoffeeMasterWidgets: WidgetBundle {
    var body: some Widget {
        BrewTimerLiveActivity()
    }
}

/// Lock Screen and Dynamic Island for the running brew; tapping opens the app at the brew.
struct BrewTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrewTimerAttributes.self) { context in
            BrewTimerLockScreenView(status: context.state)
                .widgetURL(context.attributes.deepLinkURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    BrewTimerPhase(status: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    BrewTimerClock(since: context.state.startedAt).font(.title3.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(verbatim: context.state.title).font(.caption).lineLimit(1)
                            Spacer()
                            if let target = context.state.target {
                                Text(verbatim: target).font(.caption.weight(.semibold))
                            }
                        }
                        ProgressView(value: context.state.progress)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phaseSymbol)
            } compactTrailing: {
                BrewTimerClock(since: context.state.startedAt).frame(maxWidth: 44)
            } minimal: {
                Image(systemName: context.state.phaseSymbol)
            }
            .widgetURL(context.attributes.deepLinkURL)
        }
    }
}
