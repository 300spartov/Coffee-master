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

    /// The items `fetch` returns, or `.failed` with its error.
    public init(loading fetch: @Sendable () async throws -> [Item]) async {
        do {
            self.init(try await fetch())
        } catch {
            self = .failed(error.localizedDescription)
        }
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

/// A form's view model: one save at a time (`isSaving` disables the button meanwhile).
@MainActor
public protocol SavingViewModel: AlertingViewModel {
    var isSaving: Bool { get set }
}

public extension SavingViewModel {
    /// Runs `work` unless a save is already running.
    func whileSaving(_ work: () async -> Void) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        await work()
    }
}
