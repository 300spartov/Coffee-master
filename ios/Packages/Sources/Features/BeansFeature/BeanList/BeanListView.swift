import SwiftUI
import Domain
import DesignSystem

struct BeanListView: View {
    @Bindable var viewModel: BeanListViewModel

    var body: some View {
        content
            .errorAlert($viewModel.alertMessage)
    }

    private var content: some View {
        ListStateView(viewModel.state, observe: viewModel.start, reload: viewModel.load) {
            EmptyStateView(
                title: tr("No beans yet"),
                systemImage: "leaf",
                message: tr("Add the coffee you have at home."),
                actionTitle: tr("Add Bean")
            ) {
                viewModel.didTapAdd()
            }
        } content: { beans in
            List {
                ForEach(beans) { bean in
                    Button {
                        viewModel.didSelect(bean)
                    } label: {
                        BeanRow(bean: bean)
                    }
                    .themedRow()
                }
                .onDelete { offsets in
                    let removed = offsets.map { beans[$0] }
                    Task { await viewModel.delete(removed) }
                }
            }
            .listStyle(.insetGrouped)
            .themedGroupedBackground()
        }
    }
}

struct BeanRow: View {
    let bean: Bean

    private var stockLevel: StockLevel { StockLevel(bean) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.md) {
                IconBadge("leaf.fill", tint: stockLevel.color)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(verbatim: bean.name)
                        .font(.headline)
                        .foregroundStyle(.theme.textPrimary)

                    if !bean.roaster.isEmpty {
                        Text(verbatim: bean.roaster)
                            .font(.subheadline)
                            .foregroundStyle(.theme.textSecondary)
                    }
                }

                Spacer()

                StockBadge(level: stockLevel)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(verbatim: "\(decimal(bean.remainingGrams)) / \(gramsText(bean.totalGrams))")
                        .font(.caption)
                        .foregroundStyle(.theme.textSecondary)
                    Spacer()
                    Text(bean.remainingFraction, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(stockLevel == .normal ? .theme.textSecondary : stockLevel.color)
                }

                StockBar(bean)
            }
            .padding(.top, Spacing.xxs)

            if hasMetadata {
                metadataChips
                    .padding(.top, Spacing.xxs)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }

    private var hasMetadata: Bool {
        bean.roastProfile != nil || bean.process != nil || !bean.country.isEmpty || bean.score != nil
    }

    private var metadataChips: some View {
        HStack(spacing: Spacing.xs) {
            if let roast = bean.roastProfile {
                Chip(roast.title, size: .small)
            }
            if let process = bean.process {
                Chip(process.rawValue, size: .small)
            }
            if !bean.country.isEmpty {
                Chip(bean.country, size: .small)
            }
            if let score = bean.score {
                Chip("\(decimal(score)) pts", isSelected: true, size: .small)
            }
        }
    }
}

#if DEBUG
#Preview {
    BeanListView(viewModel: BeanListViewModel(router: PreviewRouter.shared))
}
#endif
