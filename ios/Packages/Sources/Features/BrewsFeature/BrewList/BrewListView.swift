import SwiftUI
import Domain
import DesignSystem

struct BrewListView: View {
    @Bindable var viewModel: BrewListViewModel

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
                title: tr("No brews yet"),
                systemImage: "cup.and.saucer",
                message: tr("Your brews will appear here."),
                actionTitle: tr("Start a Brew")
            ) {
                viewModel.didTapAdd()
            }
        } content: { brews in
            List {
                ForEach(brews) { brew in
                    Button {
                        viewModel.didSelect(brew)
                    } label: {
                        BrewRow(brew: brew)
                    }
                    .themedRow()
                }
                .onDelete { offsets in
                    let removed = offsets.map { brews[$0] }
                    Task { await viewModel.delete(removed) }
                }
            }
            .listStyle(.insetGrouped)
            .themedGroupedBackground()
        }
    }
}

struct BrewRow: View {
    let brew: Brew

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: brew.method.systemImage)
                .font(.title2)
                .foregroundStyle(.theme.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(brew.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.theme.textPrimary)
                Text(verbatim: "\(brew.method.rawValue) · 1:\(brew.ratio.formatted(.number.precision(.fractionLength(1))))")
                    .font(.subheadline)
                    .foregroundStyle(.theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                RatingView(rating: brew.rating)
                Text(brew.date, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.theme.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    BrewListView(viewModel: BrewListViewModel(router: PreviewRouter.shared))
}
#endif
