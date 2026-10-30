import SwiftUI
import Domain
import DesignSystem

struct FilterPackFormView: View {
    @Bindable var viewModel: FilterPackFormViewModel
    @State private var isConfirmingDelete = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.load() }
                }
            case .ready:
                form
            }
        }
        .task { await viewModel.load() }
        .alert(
            tr("Error"),
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            ),
            presenting: viewModel.alertMessage
        ) { _ in
            Button(tr("OK"), role: .cancel) {}
        } message: { message in
            Text(verbatim: message)
        }
        .confirmationDialog(tr("Remove this filter pack?"), isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button(tr("Remove"), role: .destructive) {
                Task { await viewModel.delete() }
            }
        }
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

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving { ProgressView() } else { Text(tr("Save")) }
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.isValid || viewModel.isSaving)
                .accessibilityIdentifier("filterPack.save")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if viewModel.isEditing {
                    Button(tr("Remove Filter Pack"), role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .foregroundStyle(.theme.error)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("filterPack.delete")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .accessibilityIdentifier("filterPack.form")
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
