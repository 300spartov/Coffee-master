import SwiftUI
import Domain
import BrewKit
import DesignSystem

struct BrewSetupView: View {
    @Bindable var viewModel: BrewSetupViewModel

    var body: some View {
        Form {
            Section(tr("Coffee")) {
                GearRowButton(kind: .bean, model: viewModel)
            }
            .themedRow()

            if viewModel.draft.recipe.aeropress != nil {
                Section(tr("Position")) {
                    Picker(tr("Position"), selection: $viewModel.draft.recipe.aeropressOption(\.isInverted, default: false)) {
                        Label(tr("Normal"), systemImage: "arrow.up").tag(false)
                        Label(tr("Inverted"), systemImage: "arrow.down").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("setup.position")
                }
                .themedRow()
            }

            if viewModel.draft.recipe.usesDripper {
                Section(tr("Brewer")) {
                    GearRowButton(kind: .dripper, model: viewModel)
                }
                .themedRow()
            }

            if viewModel.draft.recipe.usesFilter {
                Section(tr("Filter")) {
                    GearRowButton(kind: .filter, model: viewModel)
                    if viewModel.draft.recipe.aeropress != nil {
                        let filters = $viewModel.draft.recipe.aeropressOption(\.filterCount, default: 1)
                        Stepper(value: filters, in: BrewSetup.aeropressFilterRange) {
                            LabeledContent(tr("Filters"), value: "\(filters.wrappedValue)")
                        }
                    }
                    Picker(tr("Filter"), selection: $viewModel.draft.recipe.isFilterRinsed) {
                        Text(tr("Wet")).tag(true)
                        Text(tr("Dry")).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("setup.rinse")
                }
                .themedRow()
            }

            Section(tr("Grinder & grind")) {
                GearRowButton(kind: .grinder, model: viewModel)
                NumberField(tr("Clicks"), value: $viewModel.draft.recipe.grindSetting, range: BrewSetup.grindRange, step: 1)
                    .accessibilityIdentifier("setup.clicks")
            }
            .themedRow()

            Section(tr("Parameters")) {
                NumberField(tr("Coffee"), value: $viewModel.draft.recipe.doseGrams, unit: "g", range: BrewSetup.doseRange, fractionDigits: 1)
                    .accessibilityIdentifier("setup.dose")
                NumberField(tr("Ratio (1 : X)"), value: $viewModel.draft.recipe.ratio, range: BrewSetup.ratioRange, fractionDigits: 1)
                    .accessibilityIdentifier("setup.ratio")
                Picker(tr("Pours"), selection: $viewModel.draft.recipe.pours) {
                    ForEach(Array(BrewSetup.poursRange), id: \.self) { Text(verbatim: "\($0)").tag($0) }
                }
                .accessibilityIdentifier("setup.pours")
                SliderRow(title: tr("Temperature"), value: $viewModel.draft.recipe.waterTemperature, range: viewModel.temperatureRange, unit: "°C")
                    .accessibilityIdentifier("setup.temperature")
            }
            .themedRow()

            Section {
                HStack(alignment: .lastTextBaseline) {
                    MetricView(value: "\(viewModel.draft.setup.waterMilliliters)", unit: tr("ml"), label: tr("Total water"), size: .large)
                        .accessibilityIdentifier("setup.water")
                    Spacer()
                    MetricView(value: "\(viewModel.draft.setup.bloomMilliliters)", unit: tr("ml"), label: tr("Bloom ~"))
                        .accessibilityIdentifier("setup.bloom")
                }
            } footer: {
                Text(tr("The first pour is free; the others are recalculated."))
            }
            .themedRow()

            FormActions(title: tr("Start Brewing"), isSaving: viewModel.isStarting, canSave: true, identifier: "setup") {
                Task { await viewModel.start() }
            }
        }
        .task { await viewModel.prefill() }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .accessibilityIdentifier("setup.form")
    }
}

private extension Binding where Value == BrewSetup {
    /// An AeroPress option; only shown for AeroPress, where `aeropress` is set.
    func aeropressOption<T>(_ keyPath: WritableKeyPath<AeroPressOptions, T>, default fallback: T) -> Binding<T> {
        Binding<T>(
            get: { wrappedValue.aeropress?[keyPath: keyPath] ?? fallback },
            set: { wrappedValue.aeropress?[keyPath: keyPath] = $0 }
        )
    }
}

#if DEBUG
private final class PreviewSetupRouter: BrewSetupRouting {
    static let shared = PreviewSetupRouter()
    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void) {}
    func brewSetupDidStart(_ setup: BrewSetup) {}
}

#Preview("V60") {
    BrewSetupView(viewModel: BrewSetupViewModel(method: .v60, router: PreviewSetupRouter.shared))
}

#Preview("Aeropress") {
    BrewSetupView(viewModel: BrewSetupViewModel(method: .aeropress, router: PreviewSetupRouter.shared))
}
#endif
