import SwiftUI

/// Full-width rounded button. `.primary` (accent fill) for a screen's main action,
/// `.secondary` (soft accent) for actions next to it.
public struct AppButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        case primary
        case secondary
    }

    private let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(kind == .primary ? Color.theme.accent : Color.theme.accentSoft, in: RoundedRectangle(cornerRadius: Radius.medium))
            .foregroundStyle(kind == .primary ? Color.theme.onAccent : Color.theme.accent)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

public extension ButtonStyle where Self == AppButtonStyle {
    static var primary: AppButtonStyle { AppButtonStyle(.primary) }
    static var secondary: AppButtonStyle { AppButtonStyle(.secondary) }
}

#Preview {
    VStack(spacing: Spacing.md) {
        Button("Start Brew") {}.buttonStyle(.primary)
        Button("Add Bean") {}.buttonStyle(.secondary)
        Button("Disabled") {}.buttonStyle(.primary).disabled(true)
    }
    .padding()
}
