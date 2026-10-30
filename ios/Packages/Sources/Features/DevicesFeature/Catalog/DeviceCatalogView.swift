import SwiftUI
import Domain
import DesignSystem

struct DeviceCatalogView: View {
    let viewModel: DeviceCatalogViewModel

    var body: some View {
        // Rows as drawn, so a swipe-to-delete maps to the device the user saw even if the list
        // reloads before the delete commits.
        let ownedRows = viewModel.visibleOwned
        List {
            if let name = viewModel.quickAddName {
                Section {
                    Button {
                        Task { await viewModel.quickAdd() }
                    } label: {
                        Label(tr("Add “\(name)” to my devices"), systemImage: "plus.circle.fill")
                            .foregroundStyle(.theme.accent)
                    }
                    .accessibilityIdentifier("devices.quickAdd")
                } footer: {
                    Text(tr("Not in the catalog? Add it as your own device."))
                }
                .themedRow()
            }

            if !ownedRows.isEmpty {
                Section(tr("My devices")) {
                    ForEach(ownedRows) { device in
                        Button {
                            viewModel.didSelect(device)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                IconBadge(viewModel.type.systemImage, size: 32)
                                Text(verbatim: device.name)
                                    .foregroundStyle(.theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.theme.textTertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let removed = offsets.compactMap { ownedRows.indices.contains($0) ? ownedRows[$0] : nil }
                        Task { await viewModel.delete(removed) }
                    }
                }
                .themedRow()
            }

            if !viewModel.visibleCatalog.isEmpty {
                Section(viewModel.isSearching ? tr("Search results") : tr("Catalog · \(viewModel.catalogCount)")) {
                    ForEach(viewModel.visibleCatalog) { item in
                        CatalogRow(item: item, isOwned: viewModel.isOwned(item)) {
                            Task { await viewModel.toggle(item) }
                        }
                    }
                }
                .themedRow()
            }
        }
        .listStyle(.insetGrouped)
        .themedGroupedBackground()
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
}

private struct CatalogRow: View {
    let item: CatalogDevice
    let isOwned: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: item.name)
                    .foregroundStyle(.theme.textPrimary)
                Text(verbatim: item.details)
                    .appTextStyle(.caption)
            }
            Spacer()
            Button(action: toggle) {
                Image(systemName: isOwned ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundStyle(isOwned ? Color.theme.accent : Color.theme.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOwned ? tr("Remove \(item.name)") : tr("Add \(item.name)"))
            .accessibilityIdentifier("devices.toggle.\(item.name)")
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#if DEBUG
private final class PreviewCatalogRouter: DeviceCatalogRouting {
    static let shared = PreviewCatalogRouter()
    func showAddDevice(type: DeviceType) {}
    func showEditDevice(id: Device.ID) {}
}

#Preview {
    DeviceCatalogView(viewModel: DeviceCatalogViewModel(type: .dripper, router: PreviewCatalogRouter.shared))
}
#endif
