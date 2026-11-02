import SwiftUI
import Domain
import BrewKit
import DesignSystem

/// Step 1: two big cards, Alternative and Espresso, then "Log a Brew" (made already, or at a café).
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
                        MenuCard(title: group.title, summary: group.summary, systemImage: group.systemImage, tint: group.tint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("brew.group.\(group.rawValue)")
                }

                Button {
                    viewModel.didSelectLog()
                } label: {
                    MenuCard(title: tr("Log a Brew"), summary: tr("Brewed already, or had it at a café"), systemImage: "square.and.pencil", tint: .theme.success)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("brew.log")
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
    }
}

/// A big tappable card: icon, title, summary, chevron.
private struct MenuCard: View {
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color

    var body: some View {
        LinkLabel(spacing: Spacing.lg) {
            IconBadge(systemImage, tint: tint, size: 52)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .appTextStyle(.cardTitle)
                Text(summary)
                    .appTextStyle(.caption)
                    .multilineTextAlignment(.leading)
            }
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
    func methodPickDidSelectLog() {}
}

#Preview("Groups") {
    MethodGroupsView(viewModel: MethodPickViewModel(router: PreviewMethodPickRouter.shared))
}

#Preview("Methods") {
    MethodGridView(viewModel: MethodPickViewModel(group: .espresso, router: PreviewMethodPickRouter.shared))
}
#endif
