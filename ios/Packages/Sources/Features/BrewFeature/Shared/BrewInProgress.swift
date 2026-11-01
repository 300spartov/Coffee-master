import Foundation
import Domain
import FactoryKit

/// The brew being made, saved after every change so an app kill doesn't lose it (ROADMAP 2.8; the web
/// app's draft is disabled). Kept from the moment the brew starts; the setup itself isn't (the last
/// recipe is remembered anyway). The timer keeps timestamps, so a restored brew's clocks are right.
struct BrewInProgress: Codable, Equatable {
    enum Stage: Codable, Equatable {
        /// Pour-over timer; `currentPour` is the running pour's ml as typed.
        case timer(PourOverSession, currentPour: Double?)
        /// Pour-over rating, with the corrected steps.
        case rating(PourOverSession, steps: [BrewStep], tasting: BrewTasting)
        case espresso(EspressoProgress)
    }

    var stage: Stage
    var savedAt: Date

    static let key = "brew.inProgress"
    /// Older drafts are dropped: nobody finishes a brew the next day.
    static let maximumAge: TimeInterval = 12 * 3600

    /// The saved brew, unless there's none or it's too old (then it's removed).
    static func current(now: Date = .now) -> BrewInProgress? {
        let store = Container.shared.draftStore()
        guard let draft = store.load(BrewInProgress.self, key: key) else { return nil }
        guard now.timeIntervalSince(draft.savedAt) < maximumAge else {
            store.remove(key)
            return nil
        }
        return draft
    }

    static func save(_ stage: Stage, now: Date = .now) {
        Container.shared.draftStore().save(BrewInProgress(stage: stage, savedAt: now), key: key)
    }

    static func discard() {
        Container.shared.draftStore().remove(key)
    }
}

/// An espresso after its setup: which step, the gear and recipe, the shot, milk / ice and the result.
struct EspressoProgress: Codable, Equatable {
    var step: EspressoStep
    var draft: EspressoDraft
    var shotStartedAt: Date?
    var shotStoppedAt: Date?
    var milk: MilkInfo
    var ice: IceInfo
    var shotTime: Double
    var actualYield: Double?
    var targetTDS: Double?
    var actualTDS: Double?
    var tasting: BrewTasting
}
