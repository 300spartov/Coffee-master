import SwiftUI
import Domain
import BrewKit
import DesignSystem

struct GearPickerView: View {
    @Bindable var viewModel: GearPickerViewModel

    var body: some View {
        LoadStateView(viewModel.state, observe: viewModel.start, reload: viewModel.load) {
            if viewModel.isEmpty {
                EmptyStateView(
                    title: viewModel.kind.emptyTitle,
                    systemImage: viewModel.kind.systemImage,
                    message: viewModel.kind.emptyMessage,
                    actionTitle: tr("Add")
                ) {
                    viewModel.didTapAdd()
                }
            } else {
                list
            }
        }
        .themedGroupedBackground()
        .errorAlert($viewModel.alertMessage)
    }

    private var list: some View {
        List {
            ownedSection(viewModel.owned, title: nil)
            ownedSection(viewModel.others, title: tr("For other brewers"))
            if !viewModel.suggestions.isEmpty {
                Section {
                    ForEach(viewModel.suggestions) { row in
                        rowButton(row, accessory: "plus.circle")
                    }
                } header: {
                    Text(tr("Suggested models"))
                } footer: {
                    Text(tr("Tap a model to add it to your devices."))
                }
                .themedRow()
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func ownedSection(_ rows: [GearPickerViewModel.Row], title: String?) -> some View {
        if !rows.isEmpty {
            Section {
                ForEach(rows) { row in
                    rowButton(row, accessory: viewModel.isSelected(row) ? "checkmark" : nil)
                }
            } header: {
                if let title { Text(title) }
            }
            .themedRow()
        }
    }

    private func rowButton(_ row: GearPickerViewModel.Row, accessory: String?) -> some View {
        Button {
            Task { await viewModel.didSelect(row) }
        } label: {
            HStack(spacing: Spacing.md) {
                GearRowLabel(
                    title: row.title,
                    subtitle: row.subtitle,
                    kind: viewModel.kind,
                    dripperKind: row.dripperKind,
                    stock: row.stock
                )
                if let accessory {
                    Image(systemName: accessory)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.theme.accent)
                }
            }
        }
        .accessibilityIdentifier("picker.row.\(row.title)")
    }
}

/// Icon (or dripper drawing), title, subtitle and stock bar: a picker row and a setup row.
struct GearRowLabel: View {
    let title: String
    let subtitle: String?
    let kind: GearKind
    var dripperKind: DripperKind?
    var stock: GearPickerViewModel.Row.Stock?
    var isPlaceholder = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let dripperKind {
                DripperArt(kind: dripperKind)
                    .frame(width: 36, height: 30)
            } else {
                IconBadge(kind.systemImage, tint: stock?.level.color ?? .theme.accent, size: 36)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: title)
                    .foregroundStyle(isPlaceholder ? Color.theme.textSecondary : Color.theme.textPrimary)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .appTextStyle(.caption)
                        .lineLimit(2)
                }
                if let stock {
                    StockBar(fraction: stock.fraction, level: stock.level)
                        .padding(.top, Spacing.xxs)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
