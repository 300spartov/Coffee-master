import SwiftUI
import AppCore
import DesignSystem

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section(tr("General")) {
                Picker(tr("Language"), selection: $viewModel.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeName).tag(language)
                    }
                }
                .themedRow()
                Toggle(tr("Haptics"), isOn: $viewModel.hapticsEnabled)
                    .tint(.theme.accent)
                    .themedRow()
            }

            Section {
                action(tr("Import from Web App"), systemImage: "square.and.arrow.down", perform: viewModel.didTapWebImport)
            } header: {
                Text(tr("Data"))
            } footer: {
                Text(tr("Choose the .json file exported from the Coffee Master web app. Importing again won't create duplicates."))
            }

            Section {
                Button {
                    viewModel.didTapAbout()
                } label: {
                    LinkLabel { Text(tr("About")) }
                }
                .foregroundStyle(.theme.textPrimary)
                .themedRow()
                LabeledContent(tr("Version"), value: viewModel.appVersion)
                    .themedRow()
            }

            #if DEBUG
            Section(tr("Developer")) {
                action(tr("Design System"), systemImage: "paintpalette", perform: viewModel.didTapDesignSystem)
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .themedGroupedBackground()
    }

    /// An accent action row.
    private func action(_ title: String, systemImage: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(title, systemImage: systemImage).foregroundStyle(.theme.accent)
        }
        .themedRow()
    }
}
