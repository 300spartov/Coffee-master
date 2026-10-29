import SwiftUI

/// Filled accent button for the main action of a screen ("Save", "Start Brew").
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(.theme.accent, in: RoundedRectangle(cornerRadius: Radius.medium))
            .foregroundStyle(.theme.onAccent)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

/// Soft accent button for secondary actions next to a primary one ("Add Bean", "Skip").
public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(.theme.accentSoft, in: RoundedRectangle(cornerRadius: Radius.medium))
            .foregroundStyle(.theme.accent)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

#Preview {
    VStack(spacing: Spacing.md) {
        Button("Start Brew") {}.buttonStyle(.primary)
        Button("Add Bean") {}.buttonStyle(.secondary)
        Button("Disabled") {}.buttonStyle(.primary).disabled(true)
    }
    .padding()
}
