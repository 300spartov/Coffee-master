import SwiftUI

/// Semantic text styles. All are built on Dynamic Type text styles, so they scale with the user's setting.
public enum AppTextStyle: Sendable {
    /// Big numbers: timer, dose, ratio on the brew screens.
    case metricLarge
    /// Numbers in tiles and rows.
    case metric
    /// Title of a card or list row.
    case cardTitle
    /// Section heading above a group of cards.
    case sectionTitle
    /// Body copy.
    case body
    /// Subtitles and metadata.
    case secondary
    /// Small captions and units.
    case caption
}

public extension View {
    func appTextStyle(_ style: AppTextStyle) -> some View {
        modifier(AppTextStyleModifier(style: style))
    }
}

private struct AppTextStyleModifier: ViewModifier {
    let style: AppTextStyle

    func body(content: Content) -> some View {
        switch style {
        case .metricLarge:
            content.font(.system(.largeTitle, design: .rounded, weight: .bold)).monospacedDigit()
                .foregroundStyle(.theme.textPrimary)
        case .metric:
            content.font(.system(.title3, design: .rounded, weight: .semibold)).monospacedDigit()
                .foregroundStyle(.theme.textPrimary)
        case .cardTitle:
            content.font(.headline).foregroundStyle(.theme.textPrimary)
        case .sectionTitle:
            content.font(.title3.weight(.bold)).foregroundStyle(.theme.textPrimary)
        case .body:
            content.font(.body).foregroundStyle(.theme.textPrimary)
        case .secondary:
            content.font(.subheadline).foregroundStyle(.theme.textSecondary)
        case .caption:
            content.font(.caption).foregroundStyle(.theme.textSecondary)
        }
    }
}
