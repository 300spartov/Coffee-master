import SwiftUI
import Domain
import DesignSystem

/// Espresso step 4: what came out (time, yield, TDS), the rating and notes; saves the shot.
struct EspressoResultView: View {
    @Bindable var viewModel: EspressoViewModel

    var body: some View {
        Form {
            Section(tr("Shot")) {
                NumberField(tr("Shot time"), value: $viewModel.shotTime, unit: tr("s"), range: 0...300, fractionDigits: 0)
                    .accessibilityIdentifier("espresso.shotTime")
                LabeledContent(tr("Dose"), value: "\(decimal(viewModel.draft.setup.doseGrams)) g")
                NumberField(tr("Actual yield"), value: $viewModel.actualYield, unit: "g", placeholder: decimal(viewModel.draft.setup.targetYieldGrams), range: 0...200)
                    .accessibilityIdentifier("espresso.actualYield")
                LabeledContent(tr("Actual ratio"), value: viewModel.actualRatio.map { "1:\($0.formatted(.number.precision(.fractionLength(1))))" } ?? "—")
            }
            .themedRow()

            Section(tr("Concentration")) {
                NumberField(tr("Target TDS"), value: $viewModel.targetTDS, unit: "%", placeholder: "9.0", range: 0...30, fractionDigits: 2)
                NumberField(tr("Actual TDS"), value: $viewModel.actualTDS, unit: "%", placeholder: tr("measure"), range: 0...30, fractionDigits: 2)
            }
            .themedRow()

            TastingSections(tasting: $viewModel.tasting, notesPlaceholder: tr("Body, bitterness, sweetness, balance…"))

            FormActions(title: tr("Save Shot"), isSaving: viewModel.isSaving, canSave: true, identifier: "espresso.result") {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .errorAlert($viewModel.alertMessage)
        .accessibilityIdentifier("espresso.resultForm")
    }
}
