import SwiftUI
import Domain
import DesignSystem

struct FilterPacksView: View {
    let viewModel: FilterPacksViewModel

    var body: some View {
        content
            .task { await viewModel.start() }
            .alert(
                tr("Error"),
                isPresented: Binding(
                    get: { viewModel.alertMessage != nil },
                    set: { if !$0 { viewModel.alertMessage = nil } }
                ),
                presenting: viewModel.alertMessage
            ) { _ in
                Button(tr("OK"), role: .cancel) {}
            } message: { message in
                Text(verbatim: message)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingView()
        case .empty:
            EmptyStateView(
                title: tr("No filter packs"),
                systemImage: DeviceType.filter.systemImage,
                message: tr("Add the paper filters you have."),
                actionTitle: tr("Add Filter Pack")
            ) {
                viewModel.didTapAdd()
            }
            .themedGroupedBackground()
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        case .loaded(let packs):
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

    private var level: StockLevel {
        pack.isEmpty ? .empty : (pack.isLow ? .low : .normal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: open) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    IconBadge(DeviceType.filter.systemImage, tint: level == .normal ? .theme.accent : level == .low ? .theme.warning : .theme.error)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(verbatim: pack.name)
                            .appTextStyle(.cardTitle)
                        Text(tr("\(pack.remaining) of \(pack.total) left"))
                            .appTextStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(level: level)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: Spacing.md) {
                StockBar(fraction: pack.total > 0 ? Double(pack.remaining) / Double(pack.total) : 0, level: level)
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

private struct StatusBadge: View {
    let level: StockLevel

    var body: some View {
        switch level {
        case .empty:
            badge(tr("Empty"), color: .theme.error)
        case .low:
            badge(tr("Running low"), color: .theme.warning)
        case .normal:
            EmptyView()
        }
    }

    private func badge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.12), in: Capsule())
    }
}

#if DEBUG
private final class PreviewFilterPacksRouter: FilterPacksRouting {
    static let shared = PreviewFilterPacksRouter()
    func showAddFilterPack() {}
    func showEditFilterPack(id: FilterPack.ID) {}
}

#Preview {
    FilterPacksView(viewModel: FilterPacksViewModel(router: PreviewFilterPacksRouter.shared))
}
#endif
