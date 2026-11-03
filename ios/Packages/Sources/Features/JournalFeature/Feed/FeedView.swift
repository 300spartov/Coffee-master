import SwiftUI
import Domain
import DesignSystem

/// The Journal: brew cards under day headers ("Today", "Yesterday", the date); swipe right to compare
/// or like, left to delete. The search bar and the filter sheet narrow it (3.6).
struct FeedView: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        ListStateView(viewModel.state, observe: viewModel.start, reload: viewModel.load) {
            if viewModel.filter.isEmpty {
                EmptyStateView(
                    title: tr("No brews yet"),
                    systemImage: "cup.and.saucer",
                    message: tr("Your brews will appear here."),
                    actionTitle: tr("Start a Brew")
                ) {
                    viewModel.didTapAdd()
                }
            } else {
                EmptyStateView(
                    title: tr("No brews match"),
                    systemImage: "magnifyingglass",
                    message: tr("Try other filters or search words."),
                    actionTitle: viewModel.filter.hasFilters ? tr("Clear Filters") : nil
                ) {
                    viewModel.filter.clear()
                }
            }
        } content: { days in
            List {
                ForEach(days) { day in
                    Section {
                        ForEach(day.brews) { brew in
                            BrewCard(
                                brew: brew,
                                open: { viewModel.didSelect(brew) },
                                toggleLike: { Task { await viewModel.toggleLike(brew) } },
                                isCompared: viewModel.compared.contains(brew.id),
                                toggleCompare: { viewModel.toggleCompare(brew) }
                            )
                            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .leading) {
                                let isCompared = viewModel.compared.contains(brew.id)
                                Button(isCompared ? tr("Remove") : tr("Compare"), systemImage: "scalemass") {
                                    viewModel.toggleCompare(brew)
                                }
                                .tint(isCompared ? .theme.textSecondary : .theme.accent)
                                .accessibilityIdentifier("journal.swipeCompare")
                                Button(brew.isLiked ? tr("Unlike") : tr("Like"), systemImage: brew.isLiked ? "heart.slash" : "heart") {
                                    Task { await viewModel.toggleLike(brew) }
                                }
                                .tint(.theme.error)
                                .accessibilityIdentifier("journal.swipeLike")
                            }
                            .swipeActions(edge: .trailing) {
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
            // iOS 26 shows the bar as the tab bar's accessory (`JournalModule`); before, it floats here.
            .safeAreaInset(edge: .bottom) {
                if #unavailable(iOS 26), viewModel.showsCompareBar {
                    CompareBar(viewModel: viewModel, isTabAccessory: false)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.sm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.2), value: viewModel.showsCompareBar)
            .scrollContentBackground(.hidden)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if viewModel.filter.hasFilters { FilterSummary(viewModel: viewModel) }
        }
        .themedGroupedBackground()
        .errorAlert($viewModel.alertMessage)
    }
}

/// "Compare (3)" and a close (reset) button (web: `cp-fab`): the tab bar's accessory on iOS 26 (the
/// accessory is the glass capsule), a floating bar before. Shown from the first pick; Compare is
/// disabled until there are two.
struct CompareBar: View {
    let viewModel: FeedViewModel
    let isTabAccessory: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            let compare = Button {
                viewModel.didTapCompare()
            } label: {
                Label(tr("Compare (\(viewModel.compared.count))"), systemImage: "scalemass.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, maxHeight: isTabAccessory ? .infinity : nil)
                    .contentShape(Rectangle())
            }
            .disabled(!viewModel.canCompare)
            .accessibilityIdentifier("journal.compareBar")
            if isTabAccessory {
                compare.buttonStyle(.plain).foregroundStyle(viewModel.canCompare ? Color.theme.accent : Color.theme.textTertiary)
            } else {
                compare.buttonStyle(.primary)
            }
            close
        }
        .padding(.horizontal, isTabAccessory ? Spacing.sm : 0)
    }

    /// Glass on iOS 26, a material circle before.
    @ViewBuilder
    private var close: some View {
        let button = Button {
            viewModel.resetCompare()
        } label: {
            Image(systemName: "xmark").font(.body.weight(.semibold))
        }
        .accessibilityLabel(tr("Reset"))
        .accessibilityIdentifier("journal.compareReset")
        if #available(iOS 26, *) {
            button.buttonStyle(.glass).buttonBorderShape(.circle)
        } else {
            button
                .buttonStyle(.plain)
                .foregroundStyle(.theme.textSecondary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
    }
}

/// "Filtered by: Liked, V60" over the feed while filters are on (like Mail): tap to change them,
/// ✕ to clear them.
private struct FilterSummary: View {
    let viewModel: FeedViewModel

    var body: some View {
        let filters = viewModel.filter.summary.formatted(.list(type: .and, width: .narrow))
        HStack(spacing: Spacing.sm) {
            Button {
                viewModel.didTapFilters()
            } label: {
                Text(tr("Filtered by: \(filters)"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.theme.accent)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("journal.filterSummary")
            Button(tr("Clear Filters"), systemImage: "xmark.circle.fill") {
                viewModel.filter.clear()
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(.theme.textTertiary)
            .accessibilityIdentifier("journal.filterClear")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.theme.groupedBackground, ignoresSafeAreaEdges: [])   // not up over the large title
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
