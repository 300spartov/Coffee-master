import SwiftUI
import Domain
import DesignSystem

struct BrewListView: View {
    let viewModel: BrewListViewModel

    var body: some View {
        content
            .task { await viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingView()
        case .empty:
            EmptyStateView(
                title: "No brews yet",
                systemImage: "cup.and.saucer",
                message: "Tap + to log your first brew."
            )
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
        case .loaded(let brews):
            List {
                ForEach(brews) { brew in
                    Button {
                        viewModel.didSelect(brew)
                    } label: {
                        BrewRow(brew: brew)
                    }
                    .tint(.primary)
                }
                .onDelete { offsets in
                    let removed = offsets.map { brews[$0] }
                    Task { await viewModel.delete(removed) }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct BrewRow: View {
    let brew: Brew

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: brew.method.systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(brew.displayTitle)
                    .font(.headline)
                Text("\(brew.method.rawValue) · 1:\(brew.ratio, format: .number.precision(.fractionLength(1)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                RatingView(rating: brew.rating)
                Text(brew.date, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    BrewListView(viewModel: BrewListViewModel(repository: PreviewBrewRepository(), router: PreviewRouter.shared))
}
#endif
