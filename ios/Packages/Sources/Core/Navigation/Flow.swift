import UIKit
import DeepLinks

/// A navigation flow owns one UIKit container (usually a `StackRouter`) and implements
/// the routing protocols of the features it hosts.
///
/// Flows live in the app target — the composition layer — so features stay unaware of each other.
@MainActor
public protocol Flow: AnyObject {
    /// Installed into the parent container (tab bar, window, modal).
    var rootViewController: UIViewController { get }

    /// Builds the initial screen(s). Called once.
    func start()

    func canHandle(_ deepLink: DeepLink) -> Bool

    /// Rebuilds navigation state for `deepLink`. Called only when `canHandle` returned `true`,
    /// after the root router has dismissed any modals and selected this flow.
    func handle(_ deepLink: DeepLink)
}
