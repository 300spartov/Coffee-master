import SwiftUI
import Domain
import DesignSystem

/// Espresso step 2: the shot timer, aiming for 27 s.
struct EspressoShotView: View {
    let viewModel: EspressoViewModel

    private var setup: EspressoSetup { viewModel.draft.setup }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                HStack {
                    MetricView(value: clockText(viewModel.shotElapsed), label: tr("Shot time"), size: .large)
                    Spacer()
                    MetricView(value: decimal(setup.doseGrams), unit: "g", label: tr("Dose"))
                    Spacer()
                    MetricView(value: decimal(setup.targetYieldGrams), unit: "g", label: tr("Target"))
                }
                .cardStyle()

                VStack(spacing: Spacing.md) {
                    Text(phaseTitle)
                        .appTextStyle(.caption)
                        .foregroundStyle(viewModel.hasReachedTarget ? Color.theme.success : Color.theme.accent)
                    Text(verbatim: "\(Int(viewModel.shotElapsed.rounded(.down)))")
                        .font(.system(size: 72, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.theme.textPrimary)
                        .accessibilityIdentifier("espresso.seconds")
                    Text(tr("seconds")).appTextStyle(.caption)
                    VStack(spacing: Spacing.xs) {
                        HStack {
                            Text(verbatim: "0")
                            Spacer()
                            Text(tr("Target \(targetSeconds) s"))
                        }
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.theme.textTertiary)
                        ProgressBar(fraction: viewModel.shotProgress, color: viewModel.hasReachedTarget ? .theme.success : .theme.accent)
                    }
                }
                .frame(maxWidth: .infinity)
                .cardStyle()

                HStack(spacing: Spacing.md) {
                    BigButton(title: tr("Start"), subtitle: tr("start the pump"), systemImage: "play.fill", tint: .theme.accent, isActive: false) {
                        viewModel.startShot()
                    }
                    .disabled(viewModel.isShotRunning)
                    .accessibilityIdentifier("espresso.start")
                    BigButton(title: tr("Stop"), subtitle: tr("when it blondes"), systemImage: "stop.fill", tint: .theme.error, isActive: viewModel.isShotRunning) {
                        viewModel.stopShot()
                    }
                    .disabled(!viewModel.isShotRunning)
                    .accessibilityIdentifier("espresso.stop")
                }
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
        .task { await viewModel.run() }
    }

    private let targetSeconds = Int(EspressoSetup.targetShotTime)

    private var phaseTitle: String {
        if viewModel.shotStoppedAt != nil { return tr("Done") }
        if !viewModel.isShotRunning { return tr("Ready to start") }
        return viewModel.hasReachedTarget ? tr("Optimal time!") : tr("Extracting…")
    }
}
