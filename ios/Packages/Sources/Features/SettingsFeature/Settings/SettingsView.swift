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
                    viewModel.didTapWebImport()
                } label: {
                    Label("Import from Web App", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.theme.accent)
                }
                .themedRow()
            } header: {
                Text("Data")
            } footer: {
                Text("Choose the .json file exported from the Coffee Master web app. Importing again won't create duplicates.")
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

            #if DEBUG
            Section("Developer") {
                Button {
                    viewModel.didTapDesignSystem()
                } label: {
                    Label("Design System", systemImage: "paintpalette")
                        .foregroundStyle(.theme.accent)
                }
                .themedRow()
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .themedGroupedBackground()
    }
}
