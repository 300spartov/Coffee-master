import SwiftUI
import DesignSystem

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section("General") {
                Toggle("Haptics", isOn: $viewModel.hapticsEnabled)
            }

            Section("Shortcuts") {
                Button {
                    viewModel.didTapNewBrew()
                } label: {
                    Label("Log a New Brew", systemImage: "plus.circle")
                }
            }

            Section {
                Button {
                    viewModel.didTapAbout()
                } label: {
                    HStack {
                        Text("About")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .tint(.primary)
                LabeledContent("Version", value: viewModel.appVersion)
            }
        }
        .listStyle(.insetGrouped)
    }
}
