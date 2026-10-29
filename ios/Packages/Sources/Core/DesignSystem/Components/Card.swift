import SwiftUI

/// Rounded `surface` container: brew cards, bean bags, stat groups.
public struct Card<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    public init(padding: CGFloat = Spacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(padding: padding)
    }
}

public extension View {
    /// Card look for any view: padding, `surface` background, large radius.
    func cardStyle(padding: CGFloat = Spacing.lg) -> some View {
        self
            .padding(padding)
            .background(.theme.surface, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }
}

#Preview {
    Card {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Ethiopia Yirgacheffe").appTextStyle(.cardTitle)
            Text("V60 · 1:16").appTextStyle(.secondary)
        }
    }
    .padding()
    .themedGroupedBackground()
}
