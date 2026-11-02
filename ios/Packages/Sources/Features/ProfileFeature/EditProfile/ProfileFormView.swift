import SwiftUI
import Domain
import DesignSystem

struct ProfileFormView: View {
    @Bindable var viewModel: ProfileFormViewModel

    var body: some View {
        LoadStateView(viewModel.state) {
            Task { await viewModel.load() }
        } content: {
            Form {
                Section {
                    field(tr("Name"), prompt: tr("Name or nickname"), text: $viewModel.name, identifier: "profileForm.name")
                        .textInputAutocapitalization(.words)
                    field(tr("City"), prompt: tr("City"), text: $viewModel.location, identifier: "profileForm.location")
                        .textInputAutocapitalization(.words)
                }
                .themedRow()

                Section {
                    Picker(tr("Category"), selection: $viewModel.title) {
                        Text(tr("Not set")).tag("")
                        ForEach(viewModel.titles, id: \.self) { Text(ProfileTitle.displayName($0)).tag($0) }
                    }
                    .accessibilityIdentifier("profileForm.title")
                    field(tr("Experience"), prompt: tr("e.g. 2 years"), text: $viewModel.experience, identifier: "profileForm.experience")
                }
                .themedRow()

                FormActions(isSaving: viewModel.isSaving, canSave: true, identifier: "profileForm") {
                    Task { await viewModel.save() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .themedGroupedBackground()
        .task { await viewModel.load() }
        .errorAlert($viewModel.alertMessage)
        .accessibilityIdentifier("profileForm")
    }

    /// A labelled text field (the label stays once it's filled in).
    private func field(_ title: String, prompt: String, text: Binding<String>, identifier: String) -> some View {
        LabeledContent(title) {
            TextField(title, text: text, prompt: Text(prompt))
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(identifier)
        }
    }
}

#if DEBUG
#Preview {
    ProfileFormView(viewModel: ProfileFormViewModel(router: PreviewRouter.shared))
}
#endif
