import FactoryKit

public extension Container {
    /// Toast presenter. Default does nothing (previews, tests); the app registers its `ToastCenter`.
    var toasts: Factory<any ToastPresenting> {
        self { @MainActor in SilentToastPresenter() }.cached
    }
}

/// Swallows toasts. Used where no window exists (previews, unit tests).
@MainActor
public final class SilentToastPresenter: ToastPresenting {
    public init() {}
    public func show(_ toast: Toast) {}
}
