import SwiftUI
import PhotosUI
import Domain
import DesignSystem

/// A photo from the library, or an emoji (the first cell is the name's letter) on a background color,
/// with a preview.
struct AvatarPickerView: View {
    @Bindable var viewModel: AvatarPickerViewModel
    @State private var photoItem: PhotosPickerItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 6)

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                AvatarView(profile: viewModel.profile, size: 96)

                HStack(spacing: Spacing.md) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(tr("Choose Photo"), systemImage: "photo.on.rectangle")
                    }
                    .accessibilityIdentifier("avatar.photo")
                    if viewModel.profile.avatar.photo != nil {
                        Button(tr("Remove Photo"), role: .destructive) { Task { await viewModel.removePhoto() } }
                            .accessibilityIdentifier("avatar.removePhoto")
                    }
                }
                .font(.subheadline.weight(.semibold))

                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    cell(nil, label: viewModel.profile.initials)
                    ForEach(Avatar.emojiPresets, id: \.self) { cell($0, label: $0) }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(tr("Background")).appTextStyle(.caption)
                    HStack(spacing: Spacing.sm) {
                        ForEach(Avatar.colorPresets, id: \.self) { hex in
                            let isSelected = viewModel.profile.avatar.colorHex == hex
                            Button {
                                Task { await viewModel.pick(color: hex) }
                            } label: {
                                Circle()
                                    .fill(AvatarView.color(Avatar(colorHex: hex).color))
                                    .frame(height: 36)
                                    .overlay(Circle().strokeBorder(isSelected ? Color.theme.accent : Color.theme.separator, lineWidth: isSelected ? 3 : 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(hex)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                        // Any other color: the system picker (its swatch is the last circle).
                        ColorPicker(tr("Any color"), selection: customColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .overlay(Circle().strokeBorder(viewModel.hasCustomColor ? Color.theme.accent : .clear, lineWidth: 3).frame(width: 36, height: 36))
                            .accessibilityIdentifier("avatar.customColor")
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
        .task { await viewModel.load() }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { await viewModel.pick(photo: data) }
                photoItem = nil
            }
        }
        .errorAlert($viewModel.alertMessage)
        .accessibilityIdentifier("avatarPicker")
    }

    /// The custom color, as the picker edits it (shown at once, saved after a pause).
    private var customColor: Binding<Color> {
        Binding(
            get: { AvatarView.color(viewModel.profile.avatar.color) },
            set: { viewModel.pickCustom(color: AvatarView.hex($0)) }
        )
    }

    /// An emoji, or (`nil`) the name's letter.
    private func cell(_ emoji: String?, label: String) -> some View {
        let isSelected = viewModel.profile.avatar.photo == nil && viewModel.profile.avatar.emoji == emoji
        return Button {
            Task { await viewModel.pick(emoji: emoji) }
        } label: {
            Text(verbatim: label)
                .font(.title2.weight(emoji == nil ? .bold : .regular))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(isSelected ? Color.theme.accentSoft : Color.theme.fill, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous).strokeBorder(isSelected ? Color.theme.accent : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("avatar.\(label)")
    }
}
