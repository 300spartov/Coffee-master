import SwiftUI

// Standard loading / empty / error screens so every feature renders view states the same way.

public struct LoadingView: View {
    public init() {}

    public var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct EmptyStateView: View {
    private let title: String
    private let systemImage: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    /// Pass `actionTitle` + `action` to offer the next step ("Add your first bean").
    public init(title: String, systemImage: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.theme.textPrimary)
        } description: {
            Text(message).foregroundStyle(.theme.textSecondary)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    // ContentUnavailableView proposes a narrow width to actions; give the button room.
                    .frame(width: 240)
            }
        }
    }
}

public struct ErrorStateView: View {
    private let message: String
    private let retry: (() -> Void)?

    public init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label(tr("Something went wrong"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button(tr("Retry"), action: retry)
                    .buttonStyle(.primary)
                    .frame(width: 240)
            }
        }
    }
}
