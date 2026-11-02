import SwiftUI
import Domain
import BrewKit
import DesignSystem

/// Espresso step 4: what came out (time, yield, TDS), the rating and notes; saves the shot.
struct EspressoResultView: View {
    @Bindable var viewModel: EspressoViewModel

    var body: some View {
        Form {
            Section(tr("Shot")) {
                NumberField(tr("Shot time"), value: $viewModel.shot.shotTime, unit: tr("s"), range: 0...300, fractionDigits: 0)
                    .accessibilityIdentifier("espresso.shotTime")
                LabeledContent(tr("Dose"), value: gramsText(viewModel.draft.setup.doseGrams))
                NumberField(tr("Actual yield"), value: $viewModel.shot.actualYield, unit: "g", placeholder: decimal(viewModel.draft.setup.targetYieldGrams), range: 0...200)
                    .accessibilityIdentifier("espresso.actualYield")
                LabeledContent(tr("Actual ratio"), value: viewModel.actualRatio.map(ratioText) ?? "—")
            }
            .themedRow()

            Section(tr("Concentration")) {
                NumberField(tr("Target TDS"), value: $viewModel.shot.targetTDS, unit: "%", placeholder: "9.0", range: 0...30, fractionDigits: 2)
                NumberField(tr("Actual TDS"), value: $viewModel.shot.actualTDS, unit: "%", placeholder: tr("measure"), range: 0...30, fractionDigits: 2)
            }
            .themedRow()

            TastingSections(tasting: $viewModel.shot.tasting, notesPlaceholder: tr("Body, bitterness, sweetness, balance…"))

            FormActions(title: tr("Save Shot"), isSaving: viewModel.isSaving, identifier: "espresso.result") {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .errorAlert($viewModel.alertMessage)
        .accessibilityIdentifier("espresso.resultForm")
    }
}
