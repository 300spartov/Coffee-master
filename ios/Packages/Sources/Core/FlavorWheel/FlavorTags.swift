import SwiftUI
import DesignSystem

/// A brew's saved flavors or aromas as chips in their wheel colors (web: the brew card's tags).
/// Labels that aren't on the wheel (older or typed-in notes) show as plain chips.
public struct FlavorTags: View {
    private let labels: [String]

    public init(_ labels: [String]) {
        self.labels = labels
    }

    public var body: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(labels, id: \.self) { label in
                let path = FlavorTaxonomy.path(forLabel: label)
                Text(verbatim: path?.localizedParts.last ?? label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .foregroundStyle(path.map { Color(hex: FlavorColor.text(on: $0.color)) } ?? .theme.textPrimary)
                    .background(path.map { Color(hex: $0.color) } ?? .theme.fill, in: Capsule())
            }
        }
    }
}

nonisolated public extension FlavorPath {
    /// The block's color on the wheel (notes and groups shade their category's color).
    var color: UInt32 {
        guard let category else { return 0x888888 }
        guard let group, let groupIndex = category.groups.firstIndex(of: group) else { return category.color }
        guard let note, let index = group.notes.firstIndex(where: { $0.uk == note }) else {
            return FlavorColor.group(category, groupIndex)
        }
        return FlavorColor.note(category, groupIndex, index, of: group.notes.count)
    }
}

#Preview {
    FlavorTags(["Манго", "Ваніль", "Fruity", "Something else"]).padding()
}
