import SwiftUI
import Domain
import DesignSystem
import BrewKit

/// The feed's filters, handed to the flow to open the filter sheet with (`JournalModule.makeFilters`).
/// Opaque outside the feature.
public final class FeedFilters {
    let feed: FeedViewModel

    init(feed: FeedViewModel) {
        self.feed = feed
    }
}

/// The Journal's filter sheet (like Mail's): liked, a rating range and methods. Changes apply to the
/// feed at once; Done closes it.
struct FeedFiltersView: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        Form {
            Section {
                Toggle(tr("Liked"), systemImage: "heart", isOn: $viewModel.filter.isLikedOnly)
                    .accessibilityIdentifier("filters.liked")
            }
            .themedRow()

            Section {
                RangeSlider(
                    $viewModel.filter.rating,
                    in: BrewFilter.ratingBounds,
                    step: 0.5,
                    labels: (tr("Lowest rating"), tr("Highest rating")),
                    format: ratingText
                )
                .accessibilityIdentifier("filters.rating")
            } header: {
                HStack {
                    Text(tr("Rating"))
                    Spacer()
                    Text(verbatim: viewModel.filter.ratingRangeText ?? tr("Any"))
                }
            }
            .themedRow()

            Section {
                ForEach(viewModel.methods, id: \.self) { method in
                    let isOn = viewModel.filter.methods.contains(method)
                    Button {
                        viewModel.filter.methods.formSymmetricDifference([method])
                    } label: {
                        HStack {
                            Label(method.rawValue, systemImage: method.systemImage).foregroundStyle(.theme.textPrimary)
                            Spacer()
                            if isOn { Image(systemName: "checkmark").foregroundStyle(.theme.accent) }
                        }
                    }
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityIdentifier("filters.method")
                }
            } header: {
                Text(tr("Method"))
            } footer: {
                Text(tr("None picked: every method."))
            }
            .themedRow()

            if viewModel.filter.hasFilters {
                Section {
                    Button(tr("Clear Filters"), role: .destructive) { viewModel.filter.clear() }
                        .accessibilityIdentifier("filters.clear")
                }
                .themedRow()
            }
        }
        .themedGroupedBackground()
    }
}

#if DEBUG
#Preview {
    FeedFiltersView(viewModel: FeedViewModel(router: PreviewRouter.shared))
}
#endif
