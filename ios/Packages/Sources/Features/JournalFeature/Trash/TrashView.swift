import SwiftUI
import Domain
import DesignSystem
import BrewKit

/// Deleted brews, newest first, with the days left before they're purged. Swipe right to restore,
/// left to delete for good; Empty Trash at the bottom.
struct TrashView: View {
    @Bindable var viewModel: TrashViewModel
    @State private var isConfirmingEmpty = false

    var body: some View {
        ListStateView(viewModel.state) {
            Task { await viewModel.load() }
        } empty: {
            EmptyStateView(
                title: tr("No deleted brews"),
                systemImage: "trash",
                message: tr("Deleted brews stay here for 30 days.")
            )
        } content: { brews in
            List {
                Section {
                    ForEach(brews) { brew in
                        TrashRow(brew: brew, daysLeft: viewModel.daysLeft(brew))
                            .themedRow()
                            .swipeActions(edge: .leading) {
                                Button(tr("Restore"), systemImage: "arrow.uturn.backward") {
                                    Task { await viewModel.restore(brew) }
                                }
                                .tint(.theme.accent)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(tr("Delete"), systemImage: "trash", role: .destructive) {
                                    Task { await viewModel.deletePermanently(brew) }
                                }
                            }
                    }
                } footer: {
                    Text(tr("Brews are deleted for good 30 days after you delete them. Restoring one takes its coffee from the bag again."))
                }

                Section {
                    Button(tr("Empty Trash"), role: .destructive) { isConfirmingEmpty = true }
                        .frame(maxWidth: .infinity)
                        .themedRow()
                        .accessibilityIdentifier("trash.empty")
                }
            }
            .listStyle(.insetGrouped)
        }
        .themedGroupedBackground()
        .task { await viewModel.start() }
        .errorAlert($viewModel.alertMessage)
        .confirmationDialog(tr("Delete all these brews for good?"), isPresented: $isConfirmingEmpty, titleVisibility: .visible) {
            Button(tr("Empty Trash"), role: .destructive) { Task { await viewModel.emptyTrash() } }
        }
        .accessibilityIdentifier("trash")
    }
}

/// "Kenya", "V60 · Blackwood · Oct 29, 2026", "12 days left", with the rating ring.
private struct TrashRow: View {
    let brew: Brew
    let daysLeft: Int
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: brew.displayTitle).appTextStyle(.cardTitle)
                Text(verbatim: subtitle).appTextStyle(.caption).lineLimit(1)
                Text(tr("\(daysLeft) days left"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(daysLeft <= 3 ? Color.theme.error : Color.theme.textTertiary)
            }
            Spacer()
            RatingRing(rating: brew.rating, size: 40, lineWidth: 4)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("trash.brew")
    }

    /// The method (unless it's the title already), the café, the date.
    private var subtitle: String {
        var parts = brew.bean == nil ? [] : [brew.method.rawValue]
        if case .cafe(let place) = brew.origin, !place.isEmpty { parts.append(place) }
        parts.append(brew.date.formatted(.dateTime.day().month().year().locale(locale)))
        return parts.joined(separator: " · ")
    }
}

#if DEBUG
#Preview {
    TrashView(viewModel: TrashViewModel())
}
#endif
