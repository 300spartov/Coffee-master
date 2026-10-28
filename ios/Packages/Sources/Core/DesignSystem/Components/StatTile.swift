import SwiftUI

public struct StatTile: View {
    private let title: String
    private let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.theme.textSecondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.theme.surface, in: RoundedRectangle(cornerRadius: Radius.medium))
    }
}

#Preview {
    StatTile(title: "Dose", value: "15 g")
        .padding()
}
