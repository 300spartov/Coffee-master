import SwiftUI

/// SF Symbol on a soft rounded square: device categories, brew methods, settings rows.
public struct IconBadge: View {
    private let systemImage: String
    private let tint: Color
    private let size: CGFloat

    public init(_ systemImage: String, tint: Color = .theme.accent, size: CGFloat = 36) {
        self.systemImage = systemImage
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        IconBadge("drop")
        IconBadge("cup.and.saucer.fill", tint: .theme.info)
        IconBadge("exclamationmark.triangle.fill", tint: .theme.warning, size: 48)
    }
    .padding()
}
