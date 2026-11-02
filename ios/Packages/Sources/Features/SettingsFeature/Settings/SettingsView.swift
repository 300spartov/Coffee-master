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

            Section(tr("Shortcuts")) {
                Button {
                    viewModel.didTapNewBrew()
                } label: {
                    Label(tr("Log a New Brew"), systemImage: "plus.circle")
                        .foregroundStyle(.theme.accent)
                }
                .themedRow()
            }

            Section {
                Button {
                    viewModel.didTapWebImport()
                } label: {
                    Label(tr("Import from Web App"), systemImage: "square.and.arrow.down")
                        .foregroundStyle(.theme.accent)
                }
                .themedRow()
                Button {
                    viewModel.didTapTrash()
                } label: {
                    LinkLabel { Label(tr("Deleted Brews"), systemImage: "trash").foregroundStyle(.theme.error) }
                }
                .themedRow()
                .accessibilityIdentifier("settings.trash")
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
                Button {
                    viewModel.didTapDesignSystem()
                } label: {
                    Label(tr("Design System"), systemImage: "paintpalette")
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

/// A row that opens another screen: its label and a chevron.
private struct LinkLabel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.theme.textTertiary)
        }
    }
}
