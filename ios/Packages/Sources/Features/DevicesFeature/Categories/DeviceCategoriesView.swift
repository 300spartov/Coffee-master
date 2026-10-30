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
                        CategoryTile(
                            type: type,
                            owned: viewModel.ownedCount(type),
                            inCatalog: viewModel.catalogCount(type)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("devices.category.\(type.rawValue)")
                }

                Button {
                    viewModel.didSelectFilters()
                } label: {
                    FilterPacksTile(packs: viewModel.filterPackCount, low: viewModel.lowFilterPackCount)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("devices.category.filter")
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
        .task { await viewModel.start() }
    }
}

private struct CategoryTile: View {
    let type: DeviceType
    let owned: Int
    let inCatalog: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IconBadge(type.systemImage, size: 40)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(type.title)
                    .appTextStyle(.cardTitle)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text(owned > 0 ? tr("Owned: \(owned)") : tr("Catalog: \(inCatalog)"))
                    .appTextStyle(.caption)
                    .foregroundStyle(owned > 0 ? Color.theme.accent : Color.theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct FilterPacksTile: View {
    let packs: Int
    let low: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IconBadge(DeviceType.filter.systemImage, tint: low > 0 ? .theme.warning : .theme.accent, size: 40)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(DeviceType.filter.title)
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

    @ViewBuilder
    private var subtitle: some View {
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
