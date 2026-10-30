import SwiftUI
import Domain
import DesignSystem

struct FilterPackFormView: View {
    @Bindable var viewModel: FilterPackFormViewModel

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
            Section {
                TextField(tr("Name, e.g. Cafec Abaca 02"), text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("filterPack.name")
            }
            .themedRow()

            Section(tr("Pack size")) {
                NumberField(tr("Filters in pack"), value: $viewModel.total, unit: tr("pcs"), range: FilterPackFormViewModel.sizeRange, fractionDigits: 0)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(FilterPackFormViewModel.presetSizes, id: \.self) { size in
                            Chip("\(size)", isSelected: Int(viewModel.total) == size) {
                                viewModel.selectPreset(size)
                            }
                        }
                    }
                }
                .scrollClipDisabled()
                if viewModel.isEditing {
                    NumberField(tr("Left"), value: $viewModel.remaining, unit: tr("pcs"), range: 0...viewModel.total, fractionDigits: 0)
                }
            }
            .themedRow()

            FormActions(isSaving: viewModel.isSaving, canSave: viewModel.isValid, identifier: "filterPack", destructive: removeAction) {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .accessibilityIdentifier("filterPack.form")
    }

    private var removeAction: FormActions.Destructive? {
        guard viewModel.isEditing else { return nil }
        return .init(tr("Remove Filter Pack"), confirmation: tr("Remove this filter pack?"), confirmTitle: tr("Remove")) {
            Task { await viewModel.delete() }
        }
    }
}

#if DEBUG
private final class PreviewFilterPackFormRouter: FilterPackFormRouting {
    static let shared = PreviewFilterPackFormRouter()
    func filterPackFormDidFinish(saved pack: FilterPack?) {}
    func filterPackFormDidDelete(id: FilterPack.ID) {}
    func filterPackFormNotFound(id: FilterPack.ID) {}
}

#Preview {
    FilterPackFormView(viewModel: FilterPackFormViewModel(mode: .add, router: PreviewFilterPackFormRouter.shared))
}
#endif
