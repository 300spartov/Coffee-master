import SwiftUI
import Domain
import DesignSystem

/// The Journal: brew cards under day headers ("Today", "Yesterday", the date), swipe to delete.
struct FeedView: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
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
        } content: { days in
            List {
                ForEach(days) { day in
                    Section {
                        ForEach(day.brews) { brew in
                            BrewCard(
                                brew: brew,
                                open: { viewModel.didSelect(brew) },
                                toggleLike: { Task { await viewModel.toggleLike(brew) } }
                            )
                            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button(tr("Delete"), systemImage: "trash", role: .destructive) {
                                    Task { await viewModel.delete(brew) }
                                }
                            }
                        }
                    } header: {
                        DayHeader(date: day.date)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .themedGroupedBackground()
        .task { await viewModel.start() }
        .errorAlert($viewModel.alertMessage)
    }
}

/// "Today · 1 Nov 2026", "Yesterday · …", then "Thursday, 29 Oct 2026".
private struct DayHeader: View {
    let date: Date
    @Environment(\.locale) private var locale

    var body: some View {
        Text(verbatim: title)
            .font(.footnote.weight(.semibold))
        .foregroundStyle(.theme.textSecondary)
        .accessibilityIdentifier("journal.day")
    }

    private var title: String {
        let calendar = Calendar.current
        let day = date.formatted(.dateTime.day().month().year().locale(locale))
        let relative = calendar.isDateInToday(date) ? tr("Today") : (calendar.isDateInYesterday(date) ? tr("Yesterday") : nil)
        if let relative { return "\(relative) · \(day)" }
        return date.formatted(.dateTime.weekday(.wide).day().month().year().locale(locale))
    }
}

#if DEBUG
#Preview {
    FeedView(viewModel: FeedViewModel(router: PreviewRouter.shared))
}
#endif
