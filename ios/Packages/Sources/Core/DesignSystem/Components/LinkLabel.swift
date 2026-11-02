import SwiftUI

/// A list row that opens another screen: its label and a chevron.
public struct LinkLabel<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack {
            content
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.theme.textTertiary)
        }
    }
}
