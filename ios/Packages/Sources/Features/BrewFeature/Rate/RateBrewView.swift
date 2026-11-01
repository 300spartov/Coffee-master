import SwiftUI
import Domain
import DesignSystem

/// Rate & save for pour-over: the brew's numbers, its steps (pours can be corrected), the rating, the
/// flavor wheel and notes.
struct RateBrewView: View {
    @Bindable var viewModel: RateBrewViewModel
    @State private var showsSteps = false

    private var setup: BrewSetup { viewModel.setup }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(verbatim: setup.bean?.name ?? setup.method.rawValue).appTextStyle(.cardTitle)
                    Text(verbatim: "1:\(decimal(setup.ratio)) · \(decimal(setup.waterTemperature)) °C · \(clockText(viewModel.totalTime))")
                        .appTextStyle(.secondary)
                }
                HStack {
                    MetricView(value: clockText(viewModel.totalTime), label: tr("Time"))
                    Spacer()
                    MetricView(value: decimal(viewModel.pouredMilliliters), unit: tr("ml"), label: tr("Water poured"))
                        .accessibilityIdentifier("rate.poured")
                }
            }
            .themedRow()

            if !viewModel.steps.isEmpty {
                Section {
                    DisclosureGroup(tr("Brew steps"), isExpanded: $showsSteps) {
                        ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                            stepRow(index, step)
                        }
                        NumberField(tr("Total"), value: $viewModel.totalPoured, unit: tr("ml"), range: 0...2_000, fractionDigits: 1)
                            .fontWeight(.semibold)
                            .accessibilityIdentifier("rate.total")
                    }
                    .accessibilityIdentifier("rate.steps")
                }
                .themedRow()
            }

            TastingSections(tasting: $viewModel.tasting, notesPlaceholder: tr("Body, aftertaste, acidity…"))

            FormActions(title: tr("Save Recipe"), isSaving: viewModel.isSaving, canSave: true, identifier: "rate") {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .errorAlert($viewModel.alertMessage)
        .accessibilityIdentifier("rate.form")
    }

    @ViewBuilder
    private func stepRow(_ index: Int, _ step: BrewStep) -> some View {
        let range = "\(clockText(step.start))–\(clockText(step.end))"
        switch step.kind {
        case .pour(let milliliters):
            let number = viewModel.steps[..<index].pours.count + 1
            NumberField(
                "\(number == 1 ? tr("Bloom") : tr("Pour \(number)")) · \(range)",
                value: Binding(get: { milliliters }, set: { viewModel.setPour(at: index, milliliters: $0) }),
                unit: tr("ml"),
                range: 0...2_000,
                fractionDigits: 1
            )
        case .pause:
            LabeledContent(tr("Pause"), value: range).foregroundStyle(.theme.textSecondary)
        case .action(let action):
            LabeledContent(action.title, value: range).foregroundStyle(.theme.success)
        }
    }
}
