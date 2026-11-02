import SwiftUI
import Domain
import DesignSystem

/// The Journal: brew cards under day headers ("Today", "Yesterday", the date), swipe to delete.
struct FeedView: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        ListStateView(viewModel.state, observe: viewModel.start, reload: viewModel.load) {
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
                                toggleLike: { Task { await viewModel.toggleLike(brew) } },
                                isCompared: viewModel.compared.contains(brew.id),
                                toggleCompare: { viewModel.toggleCompare(brew) }
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
        .themedGroupedBackground()
        .errorAlert($viewModel.alertMessage)
    }
}

/// "Compare (3)" and a close (reset) button (web: `cp-fab`): the tab bar's accessory on iOS 26 (the
/// accessory is the glass capsule), a floating bar before.
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
            .accessibilityIdentifier("journal.compareBar")
            if isTabAccessory {
                compare.buttonStyle(.plain).foregroundStyle(.theme.accent)
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
