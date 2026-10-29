import SwiftUI

/// Labeled value in a small rounded tile ("Dose · 16 g").
public struct StatTile: View {
    private let title: String
    private let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).appTextStyle(.caption)
            Text(value).appTextStyle(.metric)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.theme.surface, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StatTile(title: "Dose", value: "15 g")
        .padding()
}
