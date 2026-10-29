import UIKit

/// Thin wrapper around `UINavigationController`. All push / pop / present calls go through here,
/// so flows never touch UIKit containers directly and navigation stays in one place.
public final class StackRouter: NSObject {
    public let navigationController: UINavigationController

    /// Fired when this router's stack was presented modally and the user swiped it away,
    /// so the owner can drop its reference.
    public var onInteractiveDismiss: (() -> Void)?

    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        super.init()
        // Not an appearance-proxy property, so it's set per bar. Screens opt out via `largeTitleDisplayMode`.
        navigationController.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Stack

    public func setRoot(_ viewController: UIViewController, animated: Bool = false) {
        navigationController.setViewControllers([viewController], animated: animated)
    }

    public func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    public func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }

    // MARK: - Modal

    /// Presents on top of whatever is currently presented above this stack.
    public func present(_ viewController: UIViewController, animated: Bool = true) {
        topPresenter.present(viewController, animated: animated)
    }

    /// Presents `root` in its own navigation stack above this one and returns the router driving it.
    /// Keep the returned router for as long as the modal flow is alive.
    @discardableResult
    public func presentStack(
        root: UIViewController,
        style: UIModalPresentationStyle = .automatic,
        configureSheet: ((UISheetPresentationController) -> Void)? = nil
    ) -> StackRouter {
        Self.presentStack(root: root, from: topPresenter, style: style, configureSheet: configureSheet)
    }

    /// Presents `root` in a new navigation stack from any view controller (e.g. the tab bar).
    @discardableResult
    public static func presentStack(
        root: UIViewController,
        from presenter: UIViewController,
        style: UIModalPresentationStyle = .automatic,
        configureSheet: ((UISheetPresentationController) -> Void)? = nil
    ) -> StackRouter {
        let router = StackRouter()
        router.setRoot(root)
        router.navigationController.modalPresentationStyle = style
        router.navigationController.presentationController?.delegate = router
        if let sheet = router.navigationController.sheetPresentationController {
            configureSheet?(sheet)
        }
        presenter.present(router.navigationController, animated: true)
        return router
    }

    /// Dismisses this stack itself (for routers returned by `presentStack`).
    public func close(animated: Bool = true) {
        navigationController.presentingViewController?.dismiss(animated: animated)
    }

    private var topPresenter: UIViewController {
        var top: UIViewController = navigationController
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}

extension StackRouter: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onInteractiveDismiss?()
    }
}
