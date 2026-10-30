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

#if DEBUG
private final class PreviewCategoriesRouter: DeviceCategoriesRouting {
    static let shared = PreviewCategoriesRouter()
    func showCategory(_ type: DeviceType) {}
}

#Preview {
    DeviceCategoriesView(viewModel: DeviceCategoriesViewModel(router: PreviewCategoriesRouter.shared))
}
#endif
