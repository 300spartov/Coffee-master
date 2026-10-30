import SwiftUI
import Domain
import DesignSystem

struct DeviceFormView: View {
    @Bindable var viewModel: DeviceFormViewModel
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
        .confirmationDialog(tr("Remove this device?"), isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button(tr("Remove"), role: .destructive) {
                Task { await viewModel.delete() }
            }
        }
    }

    private var form: some View {
        Form {
            Section {
                TextField(tr("Name"), text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("device.name")
                Picker(tr("Type"), selection: $viewModel.type) {
                    ForEach(viewModel.types, id: \.self) { type in
                        Label(type.title, systemImage: type.systemImage).tag(type)
                    }
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
                .accessibilityIdentifier("device.save")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if viewModel.isEditing {
                    Button(tr("Remove Device"), role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .foregroundStyle(.theme.error)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("device.delete")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
    }
}

#if DEBUG
private final class PreviewDeviceFormRouter: DeviceFormRouting {
    static let shared = PreviewDeviceFormRouter()
    func deviceFormDidFinish(saved device: Device?) {}
    func deviceFormDidDelete(id: Device.ID) {}
    func deviceFormNotFound(id: Device.ID) {}
}

#Preview {
    DeviceFormView(viewModel: DeviceFormViewModel(mode: .add(.grinder), router: PreviewDeviceFormRouter.shared))
}
#endif
