import SwiftUI
import Domain
import DesignSystem
import BrewKit
import FlavorWheel

/// A brew in the feed (web: `brew-card`): bag, method and rating ring, the key numbers, like; "Details"
/// opens the recipe, the steps and the tasting notes in tabs. Tapping the top opens the brew to edit.
struct BrewCard: View {
    enum Tab: CaseIterable {
        case recipe, steps, notes

        var title: String {
            switch self {
            case .recipe: tr("Recipe")
            case .steps: tr("Steps")
            case .notes: tr("Notes")
            }
        }
    }

    let brew: Brew
    let open: () -> Void
    let toggleLike: () -> Void
    @State private var isExpanded = false
    @State private var tab = Tab.recipe

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button(action: open) { header }
                .buttonStyle(.plain)
                .accessibilityIdentifier("journal.brew")
            stats
            footer
            if isExpanded {
                Picker(tr("Details"), selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("journal.tabs")
                switch tab {
                case .recipe: BrewRecipeDetails(brew: brew)
                case .steps: BrewStepsDetails(brew: brew)
                case .notes: BrewNotesDetails(brew: brew)
                }
            }
        }
        .cardStyle()
        // The rating's color down the leading edge, like the web card.
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: Radius.large, bottomLeadingRadius: Radius.large)
                .fill(Color.rating(brew.rating))
                .frame(width: 4)
                .padding(.vertical, 8)
        }
        .animation(.smooth(duration: 0.25), value: isExpanded)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: brew.displayTitle).appTextStyle(.cardTitle)
                if let roaster = brew.bean?.roaster, !roaster.isEmpty {
                    Text(verbatim: roaster).appTextStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(brew.date, format: .dateTime.hour().minute())
                    if case .cafe(let place) = brew.origin {
                        Image(systemName: "storefront")
                        Text(verbatim: place.isEmpty ? tr("Café") : place).lineLimit(1)
                    }
                }
                .appTextStyle(.caption)
            }
            Spacer(minLength: Spacing.sm)
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Label(brew.method.rawValue, systemImage: brew.method.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.theme.accent)
                if let device = brew.device {
                    Text(verbatim: device).appTextStyle(.caption).lineLimit(1)
                }
            }
            RatingRing(rating: brew.rating, size: 44, lineWidth: 4)
        }
        .contentShape(Rectangle())
    }

    /// Dose, ratio and time; a café drink has no recipe, only its volume.
    private var stats: some View {
        HStack {
            if brew.isCafeVisit {
                MetricView(value: decimal(brew.volumeMilliliters), unit: tr("ml"), label: tr("Volume"))
            } else {
                MetricView(value: decimal(brew.doseGrams), unit: "g", label: tr("Dose"))
                Spacer()
                MetricView(value: ratioText(brew.ratio), label: tr("Ratio"))
                Spacer()
                MetricView(value: brew.totalTime.map(clockText) ?? "—", label: tr("Time"))
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                isExpanded.toggle()
            } label: {
                Label(tr("Details"), systemImage: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline.weight(.medium))
            }
            .accessibilityIdentifier("journal.details")
            Spacer()
            Button(action: toggleLike) {
                Image(systemName: brew.isLiked ? "heart.fill" : "heart")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(brew.isLiked ? Color.theme.error : Color.theme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(tr("Like"))
            .accessibilityAddTraits(brew.isLiked ? .isSelected : [])
            .accessibilityIdentifier("journal.like")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.theme.accent)
    }
}

extension Brew {
    /// Bean name, or the method when no bean was recorded (café drinks, quick logs).
    var displayTitle: String {
        bean?.name ?? method.rawValue
    }

    /// The brewer or machine, under the method.
    var device: String? {
        (dripper ?? espressoMachine)?.name
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: Spacing.md) {
            ForEach(Brew.samples) { BrewCard(brew: $0, open: {}, toggleLike: {}) }
        }
        .padding()
    }
    .themedGroupedBackground()
}
#endif
