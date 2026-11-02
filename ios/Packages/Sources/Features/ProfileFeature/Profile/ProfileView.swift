import SwiftUI
import Domain
import DesignSystem

/// The profile card (avatar, name, category · experience, city), your counts, and the menu.
struct ProfileView: View {
    let viewModel: ProfileViewModel

    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.md) {
                    header
                    HStack {
                        count(viewModel.counts.brews, tr("Brews"))
                        count(viewModel.counts.beans, tr("Bags"))
                        count(viewModel.counts.devices, tr("Devices"))
                    }
                }
                .padding(.vertical, Spacing.sm)
                .themedRow()
            }

            Section {
                row(tr("Edit Profile"), systemImage: "person.crop.circle", identifier: "profile.edit", action: viewModel.didTapEdit)
                row(tr("Deleted Brews"), systemImage: "trash", tint: .theme.error, identifier: "profile.trash", action: viewModel.didTapTrash)
                row(tr("Settings"), systemImage: "gearshape", identifier: "profile.settings", action: viewModel.didTapSettings)
            }
        }
        .listStyle(.insetGrouped)
        .themedGroupedBackground()
        .task { await viewModel.start() }
        .accessibilityIdentifier("profile")
    }

    private var header: some View {
        HStack(spacing: Spacing.lg) {
            Button(action: viewModel.didTapAvatar) {
                AvatarView(profile: viewModel.profile, size: 72)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.theme.accent)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tr("Change avatar"))
            .accessibilityIdentifier("profile.avatar")
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.profile.name.isEmpty ? tr("Set up your profile") : viewModel.profile.name)
                    .font(.title2.bold())
                    .foregroundStyle(.theme.textPrimary)
                    .accessibilityIdentifier("profile.name")
                if !viewModel.subtitle.isEmpty {
                    Text(verbatim: viewModel.subtitle).appTextStyle(.secondary)
                }
                if !viewModel.profile.location.isEmpty {
                    CompactLabel(viewModel.profile.location, systemImage: "mappin.and.ellipse")
                        .appTextStyle(.caption)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func count(_ value: Int, _ label: String) -> some View {
        MetricView(value: "\(value)", label: label).frame(maxWidth: .infinity)
    }

    private func row(_ title: String, systemImage: String, tint: Color = .theme.accent, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LinkLabel { Label(title, systemImage: systemImage).foregroundStyle(tint) }
        }
        .themedRow()
        .accessibilityIdentifier(identifier)
    }
}

#if DEBUG
#Preview {
    ProfileView(viewModel: ProfileViewModel(router: PreviewRouter.shared))
}
#endif
