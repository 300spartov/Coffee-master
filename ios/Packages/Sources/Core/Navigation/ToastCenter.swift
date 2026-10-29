import SwiftUI
import UIKit
import AppCore
import DesignSystem
import FactoryKit

/// Shows toasts on top of everything in a window (including modals), one at a time, queued.
///
/// The toast view is added straight to the window at show time, sized to its content,
/// so it never blocks touches outside its own frame. Swipe up or wait to dismiss.
public final class ToastCenter: NSObject, ToastPresenting {
    private weak var window: UIWindow?
    private var queue: [Toast] = []
    /// The hosting controller is kept here so it lives as long as its view is on screen.
    private var current: UIHostingController<ToastView>?
    private var dismissTask: Task<Void, Never>?

    override public init() {
        super.init()
    }

    /// Call once the window exists (`AppRouter.start()`).
    public func attach(to window: UIWindow) {
        self.window = window
    }

    public func show(_ toast: Toast) {
        queue.append(toast)
        presentNextIfIdle()
    }

    // MARK: - Presentation

    private func presentNextIfIdle() {
        guard current == nil, let window, !queue.isEmpty else { return }
        let toast = queue.removeFirst()

        let host = UIHostingController(rootView: ToastView(toast: toast) { [weak self] in
            toast.action?.handler()
            self?.dismissCurrent()
        })
        host.sizingOptions = .intrinsicContentSize
        host.view.backgroundColor = .clear
        let view = host.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            view.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: Spacing.sm),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: Spacing.lg),
            view.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -Spacing.lg),
        ])
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipe.direction = .up
        view.addGestureRecognizer(swipe)

        current = host

        playHaptic(for: toast.style)
        UIAccessibility.post(notification: .announcement, argument: toast.message)

        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: -24)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            view.alpha = 1
            view.transform = .identity
        }

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(toast.duration))
            guard !Task.isCancelled else { return }
            self?.dismissCurrent()
        }
    }

    private func dismissCurrent() {
        guard let view = current?.view else { return }
        dismissTask?.cancel()
        dismissTask = nil
        current = nil
        UIView.animate(withDuration: 0.25, animations: {
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: 0, y: -24)
        }, completion: { [weak self] _ in
            view.removeFromSuperview()
            self?.presentNextIfIdle()
        })
    }

    @objc private func handleSwipe() {
        dismissCurrent()
    }

    private func playHaptic(for style: Toast.Style) {
        guard Container.shared.preferences().hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        switch style {
        case .success: generator.notificationOccurred(.success)
        case .warning: generator.notificationOccurred(.warning)
        case .error: generator.notificationOccurred(.error)
        case .info: break
        }
    }
}
