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
