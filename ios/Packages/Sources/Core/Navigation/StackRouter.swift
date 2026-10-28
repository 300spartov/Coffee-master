import UIKit

/// Thin wrapper around `UINavigationController`. All push / pop / present calls go through here,
/// so flows never touch UIKit containers directly and navigation stays in one place.
@MainActor
public final class StackRouter: NSObject {
    public let navigationController: UINavigationController

    /// Fired when this router's stack was presented modally and the user swiped it away.
    public var onInteractiveDismiss: (() -> Void)?

    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        super.init()
        // Not an appearance-proxy property, so it's set per bar. Screens opt out via `largeTitleDisplayMode`.
        navigationController.navigationBar.prefersLargeTitles = true
    }

    public var viewControllers: [UIViewController] {
        navigationController.viewControllers
    }

    // MARK: - Stack

    public func setRoot(_ viewController: UIViewController, animated: Bool = false) {
        navigationController.setViewControllers([viewController], animated: animated)
    }

    public func setStack(_ viewControllers: [UIViewController], animated: Bool = true) {
        navigationController.setViewControllers(viewControllers, animated: animated)
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
    public func present(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        topPresenter.present(viewController, animated: animated, completion: completion)
    }

    /// Presents `root` inside its own navigation stack and returns the router driving it.
    /// Keep the returned router for as long as the modal flow is alive.
    @discardableResult
    public func presentStack(
        root: UIViewController,
        style: UIModalPresentationStyle = .automatic,
        animated: Bool = true,
        configureSheet: ((UISheetPresentationController) -> Void)? = nil
    ) -> StackRouter {
        let child = StackRouter()
        child.setRoot(root)
        child.navigationController.modalPresentationStyle = style
        child.navigationController.presentationController?.delegate = child
        if let sheet = child.navigationController.sheetPresentationController {
            configureSheet?(sheet)
        }
        present(child.navigationController, animated: animated)
        return child
    }

    /// Dismisses everything presented above this stack.
    public func dismissPresented(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard navigationController.presentedViewController != nil else {
            completion?()
            return
        }
        navigationController.dismiss(animated: animated, completion: completion)
    }

    /// Dismisses this stack itself (for routers returned by `presentStack`).
    public func close(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let presenter = navigationController.presentingViewController else {
            completion?()
            return
        }
        presenter.dismiss(animated: animated, completion: completion)
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
