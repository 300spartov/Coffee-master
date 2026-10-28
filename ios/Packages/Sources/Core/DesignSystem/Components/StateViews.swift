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

    public init(title: String, systemImage: String, message: String) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
    }

    public var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
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
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button("Retry", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
            }
        }
    }
}
