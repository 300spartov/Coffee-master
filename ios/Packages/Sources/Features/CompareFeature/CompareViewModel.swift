import Foundation
import Observation
import AppCore
import Domain
import FactoryKit

/// The compare screen: timeline, rings or curve of the brews picked in the journal. Tapping a brew
/// highlights it everywhere (the others fade), like the web app.
@Observable
final class CompareViewModel {
    enum Chart: CaseIterable {
        case timeline, rings, curve

        var title: String {
            switch self {
            case .timeline: tr("Timeline")
            case .rings: tr("Rings")
            case .curve: tr("Curve")
            }
        }
    }

    /// What the timeline bars are labelled with.
    enum Unit {
        case seconds, milliliters
    }

    private let brewIDs: [Brew.ID]
    private(set) var state: LoadState = .loading
    private(set) var comparison = Comparison(brews: [])
    var chart = Chart.timeline
    var unit = Unit.seconds
    private(set) var highlighted: Brew.ID?

    @ObservationIgnored @Injected(\.brewRepository) private var repository

    init(brewIDs: [Brew.ID]) {
        self.brewIDs = brewIDs
    }

    /// The picked brews that still exist, in the order they were picked.
    func load() async {
        do {
            let brews = try await repository.fetchAll()
            comparison = Comparison(brews: brewIDs.compactMap { id in brews.first { $0.id == id } })
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleHighlight(_ entry: Comparison.Entry) {
        highlighted = highlighted == entry.id ? nil : entry.id
    }

    /// Faded while another brew is highlighted.
    func isFaded(_ entry: Comparison.Entry) -> Bool {
        highlighted != nil && highlighted != entry.id
    }
}
