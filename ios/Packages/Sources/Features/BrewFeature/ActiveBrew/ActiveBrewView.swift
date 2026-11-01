import SwiftUI
import Domain
import DesignSystem

struct ActiveBrewView: View {
    @Bindable var viewModel: ActiveBrewViewModel
    @FocusState private var isPourFieldFocused: Bool

    private var session: PourOverSession { viewModel.session }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                timers
                water
                mainButtons
                if viewModel.isPouring {
                    pourField
                }
                if session.isBetweenPours || viewModel.isPressing {
                    pauseActions
                }
                Button {
                    viewModel.stop()
                } label: {
                    Label(tr("Stop"), systemImage: "stop.fill")
                }
                .buttonStyle(.secondary)
                .disabled(session.startedAt == nil)
                .accessibilityIdentifier("active.stop")
                if !session.steps.isEmpty {
                    log
                }
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        // Back is the module's own button (it asks before discarding a started brew).
        .navigationBarBackButtonHidden()
        .task { await viewModel.run() }
        .confirmationDialog(tr("Discard this brew?"), isPresented: $viewModel.isConfirmingLeave, titleVisibility: .visible) {
            Button(tr("Discard"), role: .destructive) { viewModel.leave() }
        }
        .onChange(of: viewModel.isPouring) { _, pouring in isPourFieldFocused = pouring }
    }

    // MARK: - Timers

    private var timers: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            DripperArt(kind: session.setup.dripper.map { DripperKind(deviceName: $0.name) } ?? .cone)
                .frame(width: 84, height: 64)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("Total time")).appTextStyle(.caption)
                    Text(clockText(session.elapsed(at: viewModel.now)))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.theme.textPrimary)
                        .accessibilityIdentifier("active.time")
                }
                HStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.phaseTitle).appTextStyle(.caption)
                        Text(session.phaseElapsed(at: viewModel.now).map(clockText) ?? "—")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(phaseColor)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(tr("Pour")).appTextStyle(.caption)
                        Text(verbatim: "\(pourCount) / \(session.setup.pours)")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.theme.textPrimary)
                            .accessibilityIdentifier("active.pours")
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    /// Pours started so far (the running one counts).
    private var pourCount: Int {
        session.completedPours + (viewModel.isPouring ? 1 : 0)
    }

    private var phaseColor: Color {
        switch session.phase {
        case .pouring: .theme.info
        case .paused, .action: .theme.success
        case .pressing: .theme.accent
        case .ready, .finished: .theme.textTertiary
        }
    }

    // MARK: - Water

    private var water: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .lastTextBaseline) {
                MetricView(value: decimal(viewModel.pouredMilliliters), unit: tr("ml"), label: tr("Poured"), size: .large)
                    .accessibilityIdentifier("active.poured")
                Spacer()
                MetricView(value: decimal(viewModel.remainingMilliliters), unit: tr("ml"), label: tr("Remaining"))
            }
            // Marks where the next pours should end.
            ProgressBar(
                fraction: viewModel.pouredFraction,
                color: .theme.info,
                marks: session.nextPourMarks.map { $0 / max(session.totalMilliliters, 1) }
            )
            HStack {
                Text(viewModel.pouredFraction, format: .percent.precision(.fractionLength(0)))
                    .foregroundStyle(.theme.accent)
                Spacer()
                if let ratio = session.ratioOverPlan(poured: viewModel.pouredMilliliters) {
                    Text(verbatim: "1:\(ratio.formatted(.number.precision(.fractionLength(1))))")
                        .foregroundStyle(.theme.warning)
                }
                Spacer()
                Text(verbatim: "\(decimal(session.totalMilliliters)) \(tr("ml"))")
                    .foregroundStyle(.theme.textSecondary)
            }
            .font(.caption.weight(.semibold).monospacedDigit())
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.hints) { hint in
                    HintChip(title: pourTitle(hint.number), milliliters: decimal(hint.milliliters), state: hint.state)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Pour / pause

    private var mainButtons: some View {
        HStack(spacing: Spacing.md) {
            BigButton(
                title: viewModel.isPouring ? tr("Pouring…") : tr("Pour"),
                subtitle: pourSubtitle,
                systemImage: "drop.fill",
                tint: .theme.info,
                isActive: viewModel.isPouring
            ) {
                viewModel.pour()
            }
            .disabled(viewModel.isPouring || viewModel.isPressing || session.isFinished)
            .accessibilityIdentifier("active.pour")

            BigButton(
                title: session.isBetweenPours ? tr("Drawdown") : tr("Pause"),
                subtitle: session.isBetweenPours ? seconds(session.phaseElapsed(at: viewModel.now) ?? 0) : tr("filter drawdown"),
                systemImage: "pause.fill",
                tint: .theme.success,
                isActive: session.isBetweenPours,
                progress: viewModel.pauseProgress
            ) {
                viewModel.pause()
            }
            // Only a pour can be paused; between pours the button shows the drawdown (not greyed out).
            .disabled(session.startedAt == nil || session.isFinished)
            .allowsHitTesting(viewModel.isPouring)
            .accessibilityIdentifier("active.pause")
        }
    }

    private var pourSubtitle: String {
        switch session.phase {
        case .ready: return tr("tap to start")
        case .pouring: return tr("tap pause when done")
        default:
            let left = Int(viewModel.remainingMilliliters.rounded())
            return left > 1 ? tr("~\(left) ml left") : tr("all poured")
        }
    }

    /// How much this pour was (optional; with a scale).
    private var pourField: some View {
        HStack {
            Text(tr("This pour")).foregroundStyle(.theme.textSecondary)
            Spacer()
            TextField(
                viewModel.currentPourTarget.map(decimal) ?? "0",
                value: $viewModel.currentPour,
                format: .number.precision(.fractionLength(0...1))
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .font(.title3.weight(.semibold).monospacedDigit())
            .focused($isPourFieldFocused)
            .frame(maxWidth: 120)
            .accessibilityIdentifier("active.pourMilliliters")
            Text(tr("ml")).foregroundStyle(.theme.textSecondary)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 52)
        .background(.theme.surface, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }

    // MARK: - During the pause

    private var pauseActions: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(tr("During the pause")).appTextStyle(.caption)
            HStack(spacing: Spacing.sm) {
                ForEach([BrewAction.stir, .swirl, .shake], id: \.self) { action in
                    ActionButton(
                        title: action.title,
                        systemImage: action.systemImage,
                        isRunning: viewModel.isRunning(action),
                        progress: viewModel.isRunning(action) ? (session.phaseElapsed(at: viewModel.now) ?? 0) / PourOverSession.actionLimit : 0
                    ) {
                        viewModel.toggle(action)
                    }
                    .disabled(viewModel.isPressing)
                    .accessibilityIdentifier("active.action.\(action.rawValue)")
                }
            }
            if viewModel.isAeropress {
                Button {
                    viewModel.togglePress()
                } label: {
                    Label(viewModel.isPressing ? tr("Stop press") : tr("Press"), systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("active.press")
            }
        }
    }

    // MARK: - Log

    private var log: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(tr("Steps")).appTextStyle(.caption)
            VStack(spacing: 0) {
                ForEach(Array(session.steps.enumerated()), id: \.offset) { index, step in
                    StepRow(step: step, milliliters: pourBinding(index))
                    if index < session.steps.count - 1 { Divider() }
                }
            }
            .cardStyle(padding: Spacing.md)
        }
        .accessibilityIdentifier("active.log")
    }

    private func pourBinding(_ index: Int) -> Binding<Double>? {
        guard case .pour(let milliliters) = session.steps[index].kind else { return nil }
        return Binding(get: { milliliters }, set: { viewModel.editPour(at: index, milliliters: $0) })
    }

    // MARK: - Formatting


}

/// "12 s", counted like the clocks (whole seconds gone).
private func seconds(_ value: TimeInterval) -> String {
    let seconds = Int(value.rounded(.down))
    return tr("\(seconds) s")
}

// MARK: - Pieces

private struct HintChip: View {
    let title: String
    let milliliters: String
    let state: ActiveBrewViewModel.PourHint.State

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(title).font(.caption2.weight(.semibold))
            Text(verbatim: milliliters).font(.headline.monospacedDigit())
            Text(tr("ml")).font(.caption2)
        }
        .foregroundStyle(state == .active ? Color.white : (state == .done ? Color.theme.textTertiary : Color.theme.textSecondary))
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(state == .active ? Color.theme.info : Color.theme.fill, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .opacity(state == .done ? 0.6 : 1)
        .accessibilityElement(children: .combine)
    }
}

/// Stir / swirl / shake: tap to time it (up to 15 s), tap again to stop.
private struct ActionButton: View {
    let title: String
    let systemImage: String
    let isRunning: Bool
    let progress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle().stroke(Color.theme.success.opacity(0.2), lineWidth: 3)
                    Circle().trim(from: 0, to: progress).stroke(Color.theme.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: systemImage).font(.body.weight(.semibold))
                }
                .frame(width: 36, height: 36)
                Text(title).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(Color.theme.success)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.theme.success.opacity(isRunning ? 0.25 : 0.1), in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isRunning ? .isSelected : [])
    }
}

/// A logged step: what, when (mm:ss–mm:ss), how long; pours can be corrected.
private struct StepRow: View {
    let step: BrewStep
    let milliliters: Binding<Double>?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 96, alignment: .leading)
            Text(verbatim: "\(clockText(step.start))–\(clockText(step.end))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.theme.textPrimary)
            Text(seconds(step.duration))
                .font(.caption)
                .foregroundStyle(.theme.textSecondary)
            Spacer()
            if let milliliters {
                TextField(String("0"), value: milliliters, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .frame(width: 56)
                Text(tr("ml")).font(.caption).foregroundStyle(.theme.textSecondary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private var title: String {
        switch step.kind {
        case .pour: tr("Pour")
        case .pause: tr("Pause")
        case .action(let action): action.title
        }
    }

    private var color: Color {
        switch step.kind {
        case .pour: .theme.info
        case .pause: .theme.textSecondary
        case .action: .theme.success
        }
    }

}

extension BrewAction {
    var title: String {
        switch self {
        case .stir: tr("Stir")
        case .swirl: tr("Swirl")
        case .shake: tr("Shake")
        case .press: tr("Press")
        default: rawValue
        }
    }

    var systemImage: String {
        switch self {
        case .stir: "arrow.clockwise"
        case .swirl: "arrow.triangle.2.circlepath"
        case .shake: "waveform.path"
        default: "bolt"
        }
    }
}

#if DEBUG
private final class PreviewActiveRouter: ActiveBrewRouting {
    static let shared = PreviewActiveRouter()
    func activeBrewDidFinish(_ session: PourOverSession) {}
    func activeBrewDidLeave() {}
}

#Preview {
    ActiveBrewView(viewModel: ActiveBrewViewModel(setup: BrewSetup(method: .v60), router: PreviewActiveRouter.shared))
}
#endif
