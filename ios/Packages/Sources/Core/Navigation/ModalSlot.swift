import UIKit

/// The sheet (or full-screen modal) a flow has open, if any. Opens at most one at a time and lets the
/// flow close it. `current` is `nil` once the modal is gone, however that happened (Cancel, a swipe,
/// or `AppRouter` dismissing everything for a deep link), so a flow never acts on a stale one.
public final class ModalSlot {
    private var router: StackRouter?

    public init() {}

    /// The open modal's router, if it's really still on screen.
    public var current: StackRouter? {
        router?.isPresented == true ? router : nil
    }

    public var isPresented: Bool { current != nil }

    /// Runs `present` (which presents the modal and returns its router) unless one is already open,
    /// e.g. after a fast double tap.
    public func present(_ present: () -> StackRouter) {
        guard !isPresented else { return }
        router = present()
    }

    public func close() {
        router?.close()
        router = nil
    }
}
