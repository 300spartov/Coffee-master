import SwiftUI
import Domain
import DesignSystem

/// Espresso step 1: bag, machine, grinder, accessories and the shot's recipe.
struct EspressoSetupView: View {
    @Bindable var viewModel: EspressoViewModel

    var body: some View {
        Form {
            Section(tr("Coffee")) {
                GearRowButton(kind: .bean, model: viewModel)
            }
            .themedRow()

            Section(tr("Machine")) {
                GearRowButton(kind: .espressoMachine, model: viewModel)
            }
            .themedRow()

            Section(tr("Grinder & grind")) {
                GearRowButton(kind: .grinder, model: viewModel)
                NumberField(tr("Clicks"), value: $viewModel.draft.recipe.grindSetting, range: BrewSetup.grindRange, step: 1)
            }
            .themedRow()

            Section {
                if viewModel.ownedAccessories.isEmpty {
                    Text(tr("Add accessories in Devices → Accessories.")).appTextStyle(.secondary)
                } else {
                    ChipGroup(viewModel.ownedAccessories.map(\.id), selection: $viewModel.accessorySelection) { id in
                        viewModel.ownedAccessories.first { $0.id == id }?.name ?? ""
                    }
                }
            } header: {
                Text(tr("Accessories"))
            }
            .themedRow()

            Section(tr("Espresso parameters")) {
                NumberField(tr("Dose"), value: $viewModel.draft.recipe.doseGrams, unit: "g", range: EspressoSetup.doseRange, fractionDigits: 1)
                    .accessibilityIdentifier("espresso.dose")
                NumberField(tr("Ratio (1 : X)"), value: $viewModel.draft.recipe.ratio, range: EspressoSetup.ratioRange, fractionDigits: 1, step: 0.1)
                    .accessibilityIdentifier("espresso.ratio")
                SliderRow(title: tr("Temperature"), value: $viewModel.draft.recipe.waterTemperature, range: EspressoSetup.temperatureRange, step: 0.5, unit: "°C")
                SliderRow(title: tr("Pressure"), value: $viewModel.draft.recipe.pressureBar, range: EspressoSetup.pressureRange, step: 0.5, unit: tr("bar"))
            }
            .themedRow()

            Section {
                HStack(alignment: .lastTextBaseline) {
                    MetricView(value: "\(decimal(viewModel.draft.setup.doseGrams)) / \(decimal(viewModel.draft.setup.targetYieldGrams))", unit: "g", label: tr("Dose / Yield"), size: .large)
                        .accessibilityIdentifier("espresso.yield")
                    Spacer()
                    MetricView(value: "1:\(viewModel.draft.setup.ratio.formatted(.number.precision(.fractionLength(1))))", label: tr("Ratio"))
                }
            }
            .themedRow()

            FormActions(title: tr("Pull the Shot"), isSaving: false, canSave: true, identifier: "espresso") {
                Task { await viewModel.startShotStep() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .task { await viewModel.prefill() }
        .accessibilityIdentifier("espresso.form")
    }


}
