import Foundation
import Domain

// Navigation intents emitted by the brew wizard's view models.
// The feature doesn't know *how* navigation happens; `BrewFlow` in the app target implements these.
public protocol MethodPickRouting: AnyObject {
    /// Step 1 → 2: the methods of the chosen group.
    func showMethods(in group: MethodGroup)
    /// A method was picked; the wizard continues with setup.
    func methodPickDidSelect(_ method: BrewMethod)
    /// Cancel on step 1 closes the wizard.
    func methodPickDidCancel()
    /// "Log a Brew" on step 1: close the wizard and log a brew after the fact instead (the journal's sheet).
    func methodPickDidSelectLog()
}

/// Setup screens (pour-over and espresso) open the gear picker through this.
public protocol GearPickerPresenting: AnyObject {
    /// Opens the picker for `kind`; the flow calls `onPick` with the chosen (or newly added) item.
    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void)
}

public protocol BrewSetupRouting: GearPickerPresenting {
    /// "Start Brewing".
    func brewSetupDidStart(_ setup: BrewSetup)
}

public protocol GearPickerRouting: AnyObject {
    func gearPickerDidPick(_ pick: GearPick)
    /// "+": add a new bag / device / filter pack, then pick it.
    func gearPickerDidTapAdd(_ kind: GearKind)
}

/// A started brew left with Back (confirmed): the timer or the rating.
public protocol BrewDiscardRouting: AnyObject {
    /// The brew is discarded: back to the setup.
    func brewDidDiscard()
}

public protocol ActiveBrewRouting: BrewDiscardRouting {
    /// Stop: the session is finished (time, steps).
    func activeBrewDidFinish(_ session: PourOverSession)
}

/// The espresso steps after the setup.
public enum EspressoStep: Codable, Sendable {
    case shot
    /// Milk drinks and iced drinks only.
    case milk
    case result
}

/// A brew was saved (pour-over rating or espresso result): show the result.
public protocol BrewSavingRouting: AnyObject {
    /// `usage`: the bag and filter pack after the brew took from them, for warnings.
    func brewDidSave(_ brew: Brew, usage: StockUsage)
}

public protocol EspressoRouting: GearPickerPresenting, BrewSavingRouting {
    /// Push `step` for `brew` (`BrewModule.makeEspressoStep`).
    func espresso(_ brew: EspressoBrew, didAdvanceTo step: EspressoStep)
}

public protocol BrewResultRouting: AnyObject {
    func brewResultDidTapJournal()
    func brewResultDidTapBrewAgain()
}
