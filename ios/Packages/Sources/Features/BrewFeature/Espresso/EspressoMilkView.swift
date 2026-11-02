import SwiftUI
import Domain
import DesignSystem

/// Espresso step 3 (milk and iced drinks): the milk, or the ice and mixer.
struct EspressoMilkView: View {
    @Bindable var viewModel: EspressoViewModel

    var body: some View {
        Form {
            if viewModel.draft.recipe.needsMilk {
                Section(tr("Milk")) {
                    AutocompleteField(tr("Milk, e.g. whole 3.2%"), text: $viewModel.shot.milk.name, suggestions: viewModel.milkSuggestions)
                        .accessibilityIdentifier("espresso.milk")
                    NumberField(tr("Temperature"), value: $viewModel.shot.milk.temperature, unit: "°C", range: 0...90, fractionDigits: 0)
                    NumberField(tr("Volume"), value: $viewModel.shot.milk.volumeMilliliters, unit: tr("ml"), range: 0...600, fractionDigits: 0)
                    Picker(tr("Frothing"), selection: $viewModel.shot.milk.frother) {
                        ForEach(viewModel.frotherChoices, id: \.self) { Text(verbatim: $0).tag($0) }
                    }
                }
                .themedRow()
            }
            if viewModel.draft.recipe.needsIce {
                Section(tr("Ice & mixer")) {
                    NumberField(tr("Ice cubes"), value: $viewModel.shot.ice.cubes, range: 0...30, fractionDigits: 0)
                    AutocompleteField(tr("Juice or tonic, e.g. Schweppes"), text: $viewModel.shot.ice.mixer, suggestions: viewModel.mixerSuggestions)
                        .accessibilityIdentifier("espresso.mixer")
                }
                .themedRow()
            }
            FormActions(title: tr("Continue"), identifier: "espresso.milk") {
                viewModel.continueToResult()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .accessibilityIdentifier("espresso.milkForm")
    }
}
