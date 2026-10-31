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
}

public protocol BrewSetupRouting: AnyObject {
    /// Opens the picker for `kind`; the flow calls `onPick` with the chosen (or newly added) item.
    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void)
    /// "Start Brewing".
    func brewSetupDidStart(_ setup: BrewSetup)
}

public protocol GearPickerRouting: AnyObject {
    func gearPickerDidPick(_ pick: GearPick)
    /// "+": add a new bag / device / filter pack, then pick it.
    func gearPickerDidTapAdd(_ kind: GearKind)
}

public protocol ActiveBrewRouting: AnyObject {
    /// Stop: the session is finished (time, steps).
    func activeBrewDidFinish(_ session: PourOverSession)
    /// Back (confirmed if the brew had started): return to the setup.
    func activeBrewDidLeave()
}
