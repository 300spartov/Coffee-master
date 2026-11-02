import SwiftUI
import Domain
import BrewKit
import DesignSystem

/// After saving (web: `bv-result`): what was brewed, then the Journal or another brew.
struct BrewResultView: View {
    let brew: Brew
    let router: any BrewResultRouting

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.theme.success)
                    Text(tr("Saved!")).font(.title2.bold()).foregroundStyle(.theme.textPrimary)
                    Text(verbatim: summary).appTextStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                    StatTile(title: tr("Time"), value: brew.totalTime.map(clockText) ?? "—")
                    StatTile(
                        title: brew.espresso == nil ? tr("Water") : tr("Yield"),
                        value: "\(decimal(brew.volumeMilliliters)) \(brew.espresso == nil ? tr("ml") : "g")"
                    )
                    StatTile(title: tr("Rating"), value: ratingText(brew.rating))
                    StatTile(title: tr("Descriptors"), value: "\(brew.flavors.count + brew.aromas.count)")
                }

                VStack(spacing: Spacing.md) {
                    Button(tr("Go to Journal")) { router.brewResultDidTapJournal() }
                        .buttonStyle(.primary)
                        .accessibilityIdentifier("result.journal")
                    Button(tr("Brew Again")) { router.brewResultDidTapBrewAgain() }
                        .buttonStyle(.secondary)
                        .accessibilityIdentifier("result.again")
                }
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
        .navigationBarBackButtonHidden()
        .accessibilityIdentifier("result")
    }

    /// "Kenya · 93 °C · 1:16".
    private var summary: String {
        [brew.bean?.name, brew.waterTemperature.map(celsiusText), "1:\(decimal(brew.ratio))"]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
