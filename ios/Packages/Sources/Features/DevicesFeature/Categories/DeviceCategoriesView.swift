import SwiftUI
import Domain
import DesignSystem

struct DeviceCategoriesView: View {
    let viewModel: DeviceCategoriesViewModel

    private let columns = [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(viewModel.categories, id: \.self) { type in
                    Button {
                        viewModel.didSelect(type)
                    } label: {
                        CategoryTile(type: type) {
                            let owned = viewModel.ownedCount(type)
                            Text(owned > 0 ? tr("Owned: \(owned)") : tr("Catalog: \(viewModel.catalogCount(type))"))
                                .foregroundStyle(owned > 0 ? Color.theme.accent : Color.theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("devices.category.\(type.rawValue)")
                }

                Button {
                    viewModel.didSelectFilters()
                } label: {
                    CategoryTile(type: .filter, tint: viewModel.lowFilterPackCount > 0 ? .theme.warning : .theme.accent) {
                        filterPacksSubtitle
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("devices.category.filter")
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
        .task { await viewModel.start() }
    }

    @ViewBuilder
    private var filterPacksSubtitle: some View {
        let packs = viewModel.filterPackCount
        let low = viewModel.lowFilterPackCount
        if packs == 0 {
            Text(tr("No packs yet")).foregroundStyle(.theme.textSecondary)
        } else if low > 0 {
            Label(tr("Running low: \(low)"), systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.theme.warning)
        } else {
            Text(tr("Packs: \(packs)")).foregroundStyle(.theme.accent)
        }
    }
}

/// A category card: icon, title, and a one-line status.
private struct CategoryTile<Subtitle: View>: View {
    let type: DeviceType
    var tint: Color = .theme.accent
    @ViewBuilder let subtitle: Subtitle

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IconBadge(type.systemImage, tint: tint, size: 40)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(type.title)
                    .appTextStyle(.cardTitle)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                subtitle.appTextStyle(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
private final class PreviewCategoriesRouter: DeviceCategoriesRouting {
    static let shared = PreviewCategoriesRouter()
    func showCategory(_ type: DeviceType) {}
    func showFilterPacks() {}
}

#Preview {
    DeviceCategoriesView(viewModel: DeviceCategoriesViewModel(router: PreviewCategoriesRouter.shared))
}
#endif
