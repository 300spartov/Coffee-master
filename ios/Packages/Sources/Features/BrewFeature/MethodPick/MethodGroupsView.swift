import SwiftUI
import Domain
import BrewKit
import DesignSystem

/// Step 1: two big cards, Alternative and Espresso.
struct MethodGroupsView: View {
    let viewModel: MethodPickViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(tr("What’s brewing today?"))
                        .font(.title2.bold())
                        .foregroundStyle(.theme.textPrimary)
                    Text(tr("Choose a method"))
                        .appTextStyle(.secondary)
                }
                .padding(.bottom, Spacing.sm)

                ForEach(viewModel.groups, id: \.self) { group in
                    Button {
                        viewModel.didSelect(group: group)
                    } label: {
                        GroupCard(group: group)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("brew.group.\(group.rawValue)")
                }
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
    }
}

private struct GroupCard: View {
    let group: MethodGroup

    var body: some View {
        HStack(spacing: Spacing.lg) {
            IconBadge(group.systemImage, tint: group.tint, size: 52)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(group.title)
                    .appTextStyle(.cardTitle)
                Text(group.summary)
                    .appTextStyle(.caption)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: Spacing.xl)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension MethodGroup {
    /// Copper for alternative, steel for espresso, as in the web app.
    var tint: Color {
        switch self {
        case .alternative: .theme.accent
        case .espresso: .theme.info
        }
    }
}

#if DEBUG
private final class PreviewMethodPickRouter: MethodPickRouting {
    static let shared = PreviewMethodPickRouter()
    func showMethods(in group: MethodGroup) {}
    func methodPickDidSelect(_ method: BrewMethod) {}
    func methodPickDidCancel() {}
}

#Preview("Groups") {
    MethodGroupsView(viewModel: MethodPickViewModel(router: PreviewMethodPickRouter.shared))
}

#Preview("Methods") {
    MethodGridView(viewModel: MethodPickViewModel(group: .espresso, router: PreviewMethodPickRouter.shared))
}
#endif
