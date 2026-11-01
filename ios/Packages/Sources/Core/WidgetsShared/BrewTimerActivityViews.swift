import SwiftUI
import Domain
import DesignSystem

// The brew timer's Live Activity views, used by the Widget Extension's `ActivityConfiguration`.
// Clocks are `Text(timerInterval:)` from the start dates, so the system keeps them ticking.

/// Lock Screen / banner: title and total time, the phase with its clock and the next pour target,
/// the water poured.
public struct BrewTimerLockScreenView: View {
    let status: BrewTimerStatus

    public init(status: BrewTimerStatus) {
        self.status = status
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: status.title).font(.headline).lineLimit(1)
                Spacer()
                BrewTimerClock(since: status.startedAt).font(.title2.bold())
            }
            HStack(spacing: Spacing.sm) {
                BrewTimerPhase(status: status)
                Spacer()
                if let target = status.target {
                    Text(verbatim: target).font(.subheadline.weight(.semibold).monospacedDigit())
                }
            }
            ProgressView(value: status.progress).tint(.theme.accent)
        }
        .padding()
    }
}

/// The phase's icon, name and clock: "💧 Pour 2 0:12".
public struct BrewTimerPhase: View {
    let status: BrewTimerStatus

    public init(status: BrewTimerStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: status.phaseSymbol).foregroundStyle(.theme.accent)
            Text(verbatim: status.phaseTitle).font(.subheadline.weight(.semibold))
            if let phaseStartedAt = status.phaseStartedAt {
                BrewTimerClock(since: phaseStartedAt).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

/// Counts up from `since`, ticking on its own.
public struct BrewTimerClock: View {
    let since: Date

    public init(since: Date) {
        self.since = since
    }

    public var body: some View {
        Text(timerInterval: since...Date.distantFuture, countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

#Preview {
    BrewTimerLockScreenView(status: BrewTimerStatus(
        title: "V60 · Kenya",
        phaseTitle: "Pour 2",
        phaseSymbol: "drop.fill",
        startedAt: .now.addingTimeInterval(-75),
        phaseStartedAt: .now.addingTimeInterval(-12),
        progress: 0.4,
        target: "→ 160 ml"
    ))
}
