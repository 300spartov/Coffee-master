import SwiftUI
import Domain
import DesignSystem

struct BeanListView: View {
    @Bindable var viewModel: BeanListViewModel

    var body: some View {
        content
            .task { await viewModel.start() }
            .errorAlert($viewModel.alertMessage)
    }

    private var content: some View {
        ListStateView(viewModel.state) {
            Task { await viewModel.load() }
        } empty: {
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

    private var stockLevel: StockLevel {
        StockLevel(fraction: bean.remainingFraction)
    }

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
                    Text(verbatim: "\(formatted(bean.remainingGrams)) / \(formatted(bean.totalGrams)) g")
                        .font(.caption)
                        .foregroundStyle(.theme.textSecondary)
                    Spacer()
                    Text(bean.remainingFraction, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(stockLevel == .normal ? .theme.textSecondary : stockLevel.color)
                }

                StockBar(fraction: bean.remainingFraction, level: stockLevel)
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
                tag(roastTitle(roast))
            }
            if let process = bean.process {
                tag(process.rawValue)
            }
            if !bean.country.isEmpty {
                tag(bean.country)
            }
            if let score = bean.score {
                tag("\(formatted(score)) pts", highlighted: true)
            }
        }
    }

    /// Small capsule with a detail from the bag (data, so shown verbatim).
    private func tag(_ text: String, highlighted: Bool = false) -> some View {
        Text(verbatim: text)
            .font(.caption2.weight(highlighted ? .medium : .regular))
            .foregroundStyle(highlighted ? Color.theme.accent : Color.theme.textSecondary)
            .padding(.horizontal, Spacing.xs + 2)
            .padding(.vertical, 2)
            .background(highlighted ? Color.theme.accentSoft : Color.theme.fill, in: Capsule())
    }

    private func roastTitle(_ profile: RoastProfile) -> String {
        switch profile {
        case .filter: tr("Filter")
        case .espresso: tr("Espresso")
        case .omni: tr("Omni")
        }
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

#if DEBUG
private final class PreviewRouter: BeanListRouting {
    func showBeanDetail(id: Bean.ID) {}
    func showAddBean() {}
}

#Preview {
    BeanListView(viewModel: BeanListViewModel(router: PreviewRouter()))
}
#endif
