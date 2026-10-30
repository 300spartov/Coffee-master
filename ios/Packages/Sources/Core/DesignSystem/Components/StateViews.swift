import SwiftUI
import AppCore

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

/// Renders a `LoadState`: a spinner, the error with Retry, or `content` once ready.
public struct LoadStateView<Content: View>: View {
    private let state: LoadState
    private let retry: () -> Void
    private let content: () -> Content

    public init(_ state: LoadState, retry: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.state = state
        self.retry = retry
        self.content = content
    }

    public var body: some View {
        switch state {
        case .loading: LoadingView()
        case .failed(let message): ErrorStateView(message: message, retry: retry)
        case .ready: content()
        }
    }
}

/// Renders a `ListState`: a spinner, `empty`, the error with Retry, or `content` with the items.
public struct ListStateView<Item: Equatable & Sendable, Empty: View, Content: View>: View {
    private let state: ListState<Item>
    private let retry: () -> Void
    private let empty: () -> Empty
    private let content: ([Item]) -> Content

    public init(
        _ state: ListState<Item>,
        retry: @escaping () -> Void,
        @ViewBuilder empty: @escaping () -> Empty,
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        self.state = state
        self.retry = retry
        self.empty = empty
        self.content = content
    }

    public var body: some View {
        switch state {
        case .loading: LoadingView()
        case .empty: empty()
        case .failed(let message): ErrorStateView(message: message, retry: retry)
        case .loaded(let items): content(items)
        }
    }
}

public extension View {
    /// Shows `message` in an "Error" alert while it's set; OK clears it.
    /// For actions that failed over content that's still usable (a delete, a save).
    func errorAlert(_ message: Binding<String?>) -> some View {
        alert(
            tr("Error"),
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            ),
            presenting: message.wrappedValue
        ) { _ in
            Button(tr("OK"), role: .cancel) {}
        } message: { text in
            Text(verbatim: text)
        }
    }
}
