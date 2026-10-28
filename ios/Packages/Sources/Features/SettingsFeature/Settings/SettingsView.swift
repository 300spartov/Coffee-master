import SwiftUI
import DesignSystem

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section("General") {
                Toggle("Haptics", isOn: $viewModel.hapticsEnabled)
                    .tint(.theme.accent)
                    .themedRow()
            }

            Section("Shortcuts") {
                Button {
                    viewModel.didTapNewBrew()
                } label: {
                    Label("Log a New Brew", systemImage: "plus.circle")
                        .foregroundStyle(.theme.accent)
                }
                .themedRow()
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
                            .foregroundStyle(.theme.textTertiary)
                    }
                }
                .foregroundStyle(.theme.textPrimary)
                .themedRow()
                LabeledContent("Version", value: viewModel.appVersion)
                    .themedRow()
            }
        }
        .listStyle(.insetGrouped)
        .themedGroupedBackground()
    }
}
