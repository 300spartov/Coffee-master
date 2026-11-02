import SwiftUI
import Domain
import DesignSystem

struct DeviceFormView: View {
    @Bindable var viewModel: DeviceFormViewModel

    var body: some View {
        LoadStateView(viewModel.state, load: viewModel.load) {
            form
        }
        .errorAlert($viewModel.alertMessage)
    }

    private var form: some View {
        Form {
            Section {
                TextField(tr("Name"), text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("device.name")
                Picker(tr("Type"), selection: $viewModel.type) {
                    ForEach(DeviceType.browsable, id: \.self) { type in
                        Label(type.title, systemImage: type.systemImage).tag(type)
                    }
                }
            }
            .themedRow()

            FormActions(isSaving: viewModel.isSaving, canSave: viewModel.isValid, identifier: "device", destructive: removeAction) {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
    }

    private var removeAction: FormActions.Destructive? {
        guard viewModel.isEditing else { return nil }
        return .init(tr("Remove Device"), confirmation: tr("Remove this device?"), confirmTitle: tr("Remove")) {
            Task { await viewModel.delete() }
        }
    }
}

#if DEBUG
#Preview {
    DeviceFormView(viewModel: DeviceFormViewModel(mode: .add(.grinder), router: PreviewRouter.shared))
}
#endif
