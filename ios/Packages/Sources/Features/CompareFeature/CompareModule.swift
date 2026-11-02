import UIKit
import Domain
import Navigation

/// Public entry point of the feature (ROADMAP 3.5): compares brews picked in the journal.
public struct CompareModule {
    public init() {}

    /// The comparison of `brewIDs` (2–4, in the order they were picked); push it.
    public func makeCompare(brewIDs: [Brew.ID]) -> UIViewController {
        HostingController(
            rootView: CompareView(viewModel: CompareViewModel(brewIDs: brewIDs)),
            title: tr("Compare"),
            hidesBottomBarWhenPushed: true
        )
    }
}
