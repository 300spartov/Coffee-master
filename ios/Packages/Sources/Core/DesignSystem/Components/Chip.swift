import SwiftUI

/// Small rounded label: flavor notes, methods, filters, processing. Tappable when `action` is set.
public struct Chip: View {
    private let title: String
    private let systemImage: String?
    private let isSelected: Bool
    private let action: (() -> Void)?

    public init(_ title: String, systemImage: String? = nil, isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage).font(.caption.weight(.semibold))
            }
            Text(title).font(.subheadline.weight(.medium)).lineLimit(1)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs + 2)
        .foregroundStyle(isSelected ? Color.theme.accent : Color.theme.textPrimary)
        .background(isSelected ? Color.theme.accentSoft : Color.theme.fill, in: Capsule())
        .overlay(Capsule().strokeBorder(isSelected ? Color.theme.accent : .clear, lineWidth: 1))
        .contentShape(Capsule())
    }
}

/// Chips that wrap onto new lines. Pass `selection` to make them toggleable.
public struct ChipGroup<Item: Hashable>: View {
    private let items: [Item]
    private let title: (Item) -> String
    @Binding private var selection: Set<Item>
    private let isInteractive: Bool

    /// Toggleable chips.
    public init(_ items: [Item], selection: Binding<Set<Item>>, title: @escaping (Item) -> String) {
        self.items = items
        self.title = title
        _selection = selection
        isInteractive = true
    }

    /// Read-only chips.
    public init(_ items: [Item], title: @escaping (Item) -> String) {
        self.items = items
        self.title = title
        _selection = .constant([])
        isInteractive = false
    }

    public var body: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(items, id: \.self) { item in
                Chip(title(item), isSelected: selection.contains(item), action: isInteractive ? { toggle(item) } : nil)
            }
        }
    }

    private func toggle(_ item: Item) {
        if selection.contains(item) {
            selection.remove(item)
        } else {
            selection.insert(item)
        }
    }
}

public extension ChipGroup where Item == String {
    init(_ items: [String], selection: Binding<Set<String>>) {
        self.init(items, selection: selection) { $0 }
    }

    init(_ items: [String]) {
        self.init(items) { $0 }
    }
}

#Preview {
    @Previewable @State var selected: Set<String> = ["Jasmine"]
    VStack(alignment: .leading, spacing: Spacing.lg) {
        ChipGroup(["Jasmine", "Bergamot", "Black tea", "Honey", "Peach", "Caramel"], selection: $selected)
        ChipGroup(["V60", "Washed", "Light roast"])
        Chip("Cold Brew", systemImage: "snowflake")
    }
    .padding()
}
