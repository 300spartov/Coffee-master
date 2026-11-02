/// State of a screen that loads one thing before it can show it, e.g. a form for an existing record.
/// `DesignSystem.LoadStateView` renders it.
nonisolated public enum LoadState: Equatable, Sendable {
    case loading
    case ready
    case failed(String)
}

/// State of a list screen. `DesignSystem.ListStateView` renders it.
nonisolated public enum ListState<Item: Equatable & Sendable>: Equatable, Sendable {
    case loading
    case empty
    case loaded([Item])
    case failed(String)

    /// `.empty` or `.loaded`, depending on whether there's anything to show.
    public init(_ items: [Item]) {
        self = items.isEmpty ? .empty : .loaded(items)
    }
}

/// A view model that shows a failed action as an alert (the view binds `alertMessage` to `errorAlert`).
@MainActor
public protocol AlertingViewModel: AnyObject {
    var alertMessage: String? { get set }
}

public extension AlertingViewModel {
    /// Runs `work`; a failure becomes the alert. Returns whether it worked.
    @discardableResult
    func attempt(_ work: () async throws -> Void) async -> Bool {
        do {
            try await work()
            return true
        } catch {
            alertMessage = error.localizedDescription
            return false
        }
    }
}
