import SwiftUI
import UIKit
import Domain
import DesignSystem

/// The profile's avatar: its photo, or its emoji (or the name's first letter) on its color.
struct AvatarView: View {
    let profile: UserProfile
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let image = profile.avatar.photo.flatMap(UIImage.init(data:)) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(verbatim: profile.avatar.emoji ?? profile.initials)
                    .font(.system(size: size * (profile.avatar.emoji == nil ? 0.42 : 0.5), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Self.color(profile.avatar.color))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    /// A stored color as SwiftUI `Color` (the accent when none is set).
    static func color(_ hex: UInt32?) -> Color {
        hex.map { ThemeColor($0).color } ?? .theme.accent
    }

    /// `#RRGGBB` for a color (sRGB), as the avatar stores it.
    static func hex(_ color: Color) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let channels = [red, green, blue].map { Int((min(max($0, 0), 1) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", channels[0], channels[1], channels[2])
    }
}
