import SwiftUI
import Domain
import DesignSystem

struct BeanFormView: View {
    @Bindable var viewModel: BeanFormViewModel

    var body: some View {
        LoadStateView(viewModel.state) {
            Task { await viewModel.load() }
        } content: {
            form
        }
        .task { await viewModel.load() }
        .errorAlert($viewModel.alertMessage)
    }

    private var form: some View {
        Form {
            Section(tr("Coffee")) {
                AutocompleteField(tr("Name"), text: $viewModel.name, suggestions: viewModel.nameSuggestions)
                    .accessibilityIdentifier("bean.name")
                AutocompleteField(tr("Roaster"), text: $viewModel.roaster, suggestions: viewModel.roasterSuggestions)
                    .accessibilityIdentifier("bean.roaster")
            }
            .themedRow()

            Section {
                NumberField(tr("Bag size"), value: $viewModel.totalGrams, unit: "g", range: 1...5_000, fractionDigits: 0)
                if let remaining = viewModel.remainingGrams {
                    LabeledContent(tr("Remaining"), value: "\(remaining.formatted(.number.precision(.fractionLength(0...1)))) g")
                }
                Picker(tr("Roast profile"), selection: $viewModel.roastProfile) {
                    Text(tr("Auto")).tag(RoastProfile?.none)
                    Text(tr("Filter")).tag(RoastProfile?.some(.filter))
                    Text(tr("Espresso")).tag(RoastProfile?.some(.espresso))
                    Text(tr("Omni")).tag(RoastProfile?.some(.omni))
                }
            } header: {
                Text(tr("Bag"))
            } footer: {
                Text(tr("Auto picks the roast from the brew method."))
            }
            .themedRow()

            Section(tr("Origin")) {
                TextField(tr("Country"), text: $viewModel.country)
                    .textInputAutocapitalization(.words)
                TextField(tr("Farm"), text: $viewModel.farm)
                    .textInputAutocapitalization(.words)
                Picker(tr("Process"), selection: $viewModel.process) {
                    Text(tr("Not set")).tag(ProcessingMethod?.none)
                    ForEach(ProcessingMethod.presets, id: \.self) { process in
                        Text(verbatim: process.rawValue).tag(ProcessingMethod?.some(process))
                    }
                    if let custom = viewModel.process, !ProcessingMethod.presets.contains(custom) {
                        Text(verbatim: custom.rawValue).tag(ProcessingMethod?.some(custom))
                    }
                }
            }
            .themedRow()

            Section {
                LabeledContent(tr("Cupping score")) {
                    TextField(tr("Not set"), value: $viewModel.score, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                }
                TextField(tr("Descriptors"), text: $viewModel.descriptors, axis: .vertical)
                    .lineLimit(1...4)
            } header: {
                Text(tr("Tasting"))
            } footer: {
                if !viewModel.isScoreValid {
                    Text(tr("Score must be between 0 and 100.")).foregroundStyle(.theme.error)
                } else {
                    Text(tr("Tasting notes from the bag, e.g. jasmine, bergamot."))
                }
            }
            .themedRow()

            FormActions(
                isSaving: viewModel.isSaving,
                canSave: viewModel.isValid,
                identifier: "bean",
                destructive: deleteAction
            ) {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .accessibilityIdentifier("bean.form")
    }

    private var deleteAction: FormActions.Destructive? {
        guard viewModel.isEditing else { return nil }
        return .init(tr("Delete Bean"), confirmation: tr("Delete this bean?"), confirmTitle: tr("Delete")) {
            Task { await viewModel.delete() }
        }
    }
}

#if DEBUG
private final class PreviewBeanFormRouter: BeanFormRouting {
    static let shared = PreviewBeanFormRouter()
    func beanFormDidFinish(saved bean: Bean?) {}
    func beanFormDidDelete(id: Bean.ID) {}
    func beanFormNotFound(id: Bean.ID) {}
}

#Preview("Add") {
    BeanFormView(viewModel: BeanFormViewModel(mode: .add, router: PreviewBeanFormRouter.shared))
}

#Preview("Edit") {
    BeanFormView(viewModel: BeanFormViewModel(mode: .edit(Bean.samples[0].id), router: PreviewBeanFormRouter.shared))
}
#endif
