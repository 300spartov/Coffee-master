import SwiftUI
import Domain
import DesignSystem

struct BeanListView: View {
    let viewModel: BeanListViewModel

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
                title: tr("No beans yet"),
                systemImage: "leaf",
                message: tr("Add the coffee you have at home."),
                actionTitle: tr("Add Bean")
            ) {
                viewModel.didTapAdd()
            }
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        case .loaded(let beans):
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
                IconBadge("leaf.fill", tint: iconTint)

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

                statusBadge
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(verbatim: "\(formatted(bean.remainingGrams)) / \(formatted(bean.totalGrams)) g")
                        .font(.caption)
                        .foregroundStyle(.theme.textSecondary)
                    Spacer()
                    Text(bean.remainingFraction, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(stockLevel == .low ? .theme.warning : (bean.isEmpty ? .theme.error : .theme.textSecondary))
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

    @ViewBuilder
    private var statusBadge: some View {
        if bean.isEmpty {
            Text(tr("Empty"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.theme.error)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.theme.error.opacity(0.12), in: Capsule())
        } else if stockLevel == .low {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text(tr("Running low"))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.theme.warning)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.theme.warning.opacity(0.12), in: Capsule())
        }
    }

    private var iconTint: Color {
        switch stockLevel {
        case .empty: .theme.textSecondary
        case .low: .theme.warning
        case .normal: .theme.accent
        }
    }

    private var hasMetadata: Bool {
        bean.roastProfile != nil || bean.process != nil || !bean.country.isEmpty || bean.score != nil
    }

    @ViewBuilder
    private var metadataChips: some View {
        HStack(spacing: Spacing.xs) {
            if let roast = bean.roastProfile {
                Text(roastTitle(roast))
                    .font(.caption2)
                    .foregroundStyle(.theme.textSecondary)
                    .padding(.horizontal, Spacing.xs + 2)
                    .padding(.vertical, 2)
                    .background(Color.theme.fill, in: Capsule())
            }
            if let process = bean.process {
                Text(verbatim: process.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.theme.textSecondary)
                    .padding(.horizontal, Spacing.xs + 2)
                    .padding(.vertical, 2)
                    .background(Color.theme.fill, in: Capsule())
            }
            if !bean.country.isEmpty {
                Text(verbatim: bean.country)
                    .font(.caption2)
                    .foregroundStyle(.theme.textSecondary)
                    .padding(.horizontal, Spacing.xs + 2)
                    .padding(.vertical, 2)
                    .background(Color.theme.fill, in: Capsule())
            }
            if let score = bean.score {
                Text(verbatim: "\(formatted(score)) pts")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.theme.accent)
                    .padding(.horizontal, Spacing.xs + 2)
                    .padding(.vertical, 2)
                    .background(Color.theme.accentSoft, in: Capsule())
            }
        }
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
