import SwiftUI
import Domain
import DesignSystem
import FlavorWheel

/// The rating and taste part of a brew's form (pour-over rating, espresso result, journal edit): rating
/// ring and slider, the flavor wheel and notes. Place inside a `Form`.
public struct TastingSections: View {
    @Binding private var tasting: BrewTasting
    private let notesPlaceholder: String

    public init(tasting: Binding<BrewTasting>, notesPlaceholder: String) {
        _tasting = tasting
        self.notesPlaceholder = notesPlaceholder
    }

    public var body: some View {
        Section(tr("Rating")) {
            HStack {
                RatingRing(rating: tasting.rating, size: 52)
                VStack(spacing: Spacing.xxs) {
                    Slider(value: $tasting.rating, in: Brew.ratingRange, step: 0.1)
                        .accessibilityIdentifier("tasting.rating")
                    HStack {
                        Text(tr("Bad"))
                        Spacer()
                        Text(tr("Perfect"))
                    }
                    .appTextStyle(.caption)
                }
            }
        }
        .themedRow()

        Section(tr("Taste")) {
            FlavorWheelView(flavors: $tasting.flavors, aromas: $tasting.aromas)
                .padding(.vertical, Spacing.sm)
            TextField(notesPlaceholder, text: $tasting.notes, axis: .vertical)
                .lineLimit(2...6)
                .accessibilityIdentifier("tasting.notes")
        }
        .themedRow()
    }
}
