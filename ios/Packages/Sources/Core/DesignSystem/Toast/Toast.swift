import SwiftUI

/// A short, non-blocking message ("Brew saved", "Beans are running low", "Deleted · Undo").
///
/// Show through `ToastPresenting` — flows get it injected, view models stay unaware of UIKit.
public struct Toast: Identifiable {
    public enum Style: Sendable {
        case info
        case success
        case warning
        case error
    }

    public struct Action {
        public let title: String
        public let handler: @MainActor () -> Void

        public init(_ title: String, handler: @escaping @MainActor () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    public let id = UUID()
    public var message: String
    public var style: Style
    public var duration: TimeInterval
    public var action: Action?

    public init(_ message: String, style: Style = .info, duration: TimeInterval? = nil, action: Action? = nil) {
        self.message = message
        self.style = style
        // Toasts with an action (e.g. Undo) stay longer so there's time to tap.
        self.duration = duration ?? (action == nil ? 2.5 : 4.5)
        self.action = action
    }
}

@MainActor
public protocol ToastPresenting: AnyObject {
    func show(_ toast: Toast)
}

public extension ToastPresenting {
    func show(_ message: String, style: Toast.Style = .info) {
        show(Toast(message, style: style))
    }
}

extension Toast.Style {
    var systemImage: String {
        switch self {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var iconStyle: AnyShapeStyle {
        switch self {
        case .info: AnyShapeStyle(.theme.info)
        case .success: AnyShapeStyle(.theme.success)
        case .warning: AnyShapeStyle(.theme.warning)
        case .error: AnyShapeStyle(.theme.error)
        }
    }
}

/// Visual of a single toast. Presentation (placement, timing, gestures) is done by `ToastCenter`.
public struct ToastView: View {
    private let toast: Toast
    private let onAction: () -> Void

    public init(toast: Toast, onAction: @escaping () -> Void = {}) {
        self.toast = toast
        self.onAction = onAction
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.style.systemImage)
                .foregroundStyle(toast.style.iconStyle)
                .font(.body.weight(.semibold))
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.theme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let action = toast.action {
                Button(action.title, action: onAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.theme.accent)
                    .padding(.leading, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(.theme.elevatedSurface, in: Capsule())
        .overlay(Capsule().strokeBorder(.theme.separator, lineWidth: 0.5))
        .shadow(color: .theme.shadow, radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView(toast: Toast("Brew saved", style: .success))
        ToastView(toast: Toast("Only 8 filters left", style: .warning))
        ToastView(toast: Toast("Brew deleted", action: Toast.Action("Undo") {}))
    }
    .padding()
}
