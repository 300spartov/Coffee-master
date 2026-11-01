import SwiftUI
import Domain
import BrewKit
import DesignSystem

/// Step 2: the group's methods as a two-column grid.
struct MethodGridView: View {
    let viewModel: MethodPickViewModel

    private let columns = [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let group = viewModel.group {
                    Text(group.prompt)
                        .appTextStyle(.secondary)
                }
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(viewModel.methods, id: \.self) { method in
                        Button {
                            viewModel.didSelect(method: method)
                        } label: {
                            MethodTile(method: method, tint: viewModel.group?.tint ?? .theme.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("brew.method.\(method.rawValue)")
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
    }
}

private struct MethodTile: View {
    let method: BrewMethod
    let tint: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            IconBadge(method.systemImage, tint: tint, size: 44)
            // Method names are proper names (the same in both languages), like the web app.
            Text(verbatim: method.rawValue)
                .appTextStyle(.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: Spacing.lg)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
