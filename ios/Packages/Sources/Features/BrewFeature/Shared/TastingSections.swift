import SwiftUI
import Domain
import DesignSystem
import FlavorWheel

/// The rating and taste part of a brew's last screen (pour-over rating, espresso result): rating ring
/// and slider, the flavor wheel and notes. Place inside a `Form`.
struct TastingSections: View {
    @Binding var tasting: BrewTasting
    let notesPlaceholder: String

    var body: some View {
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

/// Saves a brew just made (taking its dose and a filter from stock) and hands it to the router.
/// Returns the error message if it failed.
func record(_ brew: Brew, in brews: any BrewRepository, then router: (any BrewSavingRouting)?) async -> String? {
    do {
        let usage = try await brews.record(brew)
        router?.brewDidSave(brew, usage: usage)
        return nil
    } catch {
        return error.localizedDescription
    }
}
