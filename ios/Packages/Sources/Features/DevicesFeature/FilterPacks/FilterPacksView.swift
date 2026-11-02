import SwiftUI
import Domain
import DesignSystem

struct FilterPacksView: View {
    @Bindable var viewModel: FilterPacksViewModel

    var body: some View {
        content
            .errorAlert($viewModel.alertMessage)
    }

    private var content: some View {
        ListStateView(viewModel.state, observe: viewModel.start, reload: viewModel.load) {
            EmptyStateView(
                title: tr("No filter packs"),
                systemImage: DeviceType.filter.systemImage,
                message: tr("Add the paper filters you have."),
                actionTitle: tr("Add Filter Pack")
            ) {
                viewModel.didTapAdd()
            }
            .themedGroupedBackground()
        } content: { packs in
            List {
                ForEach(packs) { pack in
                    FilterPackRow(
                        pack: pack,
                        open: { viewModel.didSelect(pack) },
                        useOne: { Task { await viewModel.useOne(pack) } },
                        putBackOne: { Task { await viewModel.putBackOne(pack) } }
                    )
                    .themedRow()
                }
                .onDelete { offsets in
                    let removed = offsets.compactMap { packs.indices.contains($0) ? packs[$0] : nil }
                    Task { await viewModel.delete(removed) }
                }
            }
            .listStyle(.insetGrouped)
            .themedGroupedBackground()
        }
    }
}

private struct FilterPackRow: View {
    let pack: FilterPack
    let open: () -> Void
    let useOne: () -> Void
    let putBackOne: () -> Void

    /// Filters run low at a fixed count (like the web app), not a share of the pack.
    private var level: StockLevel { StockLevel(pack) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: open) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    IconBadge(DeviceType.filter.systemImage, tint: level.color)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(verbatim: pack.name)
                            .appTextStyle(.cardTitle)
                        Text(verbatim: [pack.shape?.displayName, tr("\(pack.remaining) of \(pack.total) left")].compactMap { $0 }.joined(separator: " · "))
                            .appTextStyle(.secondary)
                    }
                    Spacer()
                    StockBadge(level: level)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: Spacing.md) {
                StockBar(pack)
                Button(action: useOne) {
                    Image(systemName: "minus.circle")
                }
                .disabled(pack.isEmpty)
                .accessibilityLabel(tr("Use one filter"))
                .accessibilityIdentifier("filters.useOne.\(pack.name)")
                Button(action: putBackOne) {
                    Image(systemName: "plus.circle")
                }
                .disabled(pack.remaining >= pack.total)
                .accessibilityLabel(tr("Put one back"))
                .accessibilityIdentifier("filters.putBackOne.\(pack.name)")
            }
            .font(.title3)
            .buttonStyle(.borderless)
            .foregroundStyle(.theme.accent)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#if DEBUG
#Preview {
    FilterPacksView(viewModel: FilterPacksViewModel(router: PreviewRouter.shared))
}
#endif
