import UIKit
import FactoryKit
import Domain
import DesignSystem
import Navigation
import BrewFeature
import BeansFeature
import DevicesFeature

/// The brew action's modal flow, presented full screen over the tabs: the brew wizard.
/// Pour-over: method pick (2.1) → setup (2.2) → brew timer (2.3) → rate & save (2.7).
/// Espresso (2.5): setup → shot → milk / ice → result. Both end on the saved-brew result.
///
/// Setup rows open a picker sheet; its "+" pushes the Beans / Devices add forms into the sheet, so a
/// missing bag or device can be added without leaving the brew.
final class BrewFlow {
    private let module: BrewModule
    private let beansModule: BeansModule
    private let devicesModule: DevicesModule
    @Injected(\.toasts) private var toasts
    private let modal = ModalSlot()
    /// The picker sheet over the setup.
    private let picker = ModalSlot()
    /// The open picker: which brew it's for (a filter pack added from it gets the method's filter
    /// shape) and how to hand the pick back to the setup screen that opened it.
    private var pickerSession: (method: BrewMethod, deliver: (GearPick) -> Void)?
    private weak var presenter: UIViewController?
    /// "Go to Journal" on the result: closes the brew and shows the Journal tab.
    private let showJournal: () -> Void
    /// "Log a Brew" on step 1: closes the brew and opens the journal's log sheet.
    private let logBrew: () -> Void

    init(module: BrewModule, beansModule: BeansModule, devicesModule: DevicesModule, presenter: UIViewController, showJournal: @escaping () -> Void, logBrew: @escaping () -> Void) {
        self.module = module
        self.showJournal = showJournal
        self.logBrew = logBrew
        self.beansModule = beansModule
        self.devicesModule = devicesModule
        self.presenter = presenter
    }

    /// Whether the brew screen is really still on screen (`AppRouter` may have dismissed it for a deep link).
    var isPresented: Bool { modal.isPresented }

    /// Opens the wizard, or the brew left unfinished (app killed mid-brew) at its step.
    func start() {
        guard let presenter else { return }
        modal.present {
            let screens = module.makeBrewInProgress(router: self) ?? [module.makeMethodGroups(router: self)]
            let stack = StackRouter.presentStack(root: screens[0], from: presenter, style: .fullScreen)
            screens.dropFirst().forEach { stack.push($0, animated: false) }
            return stack
        }
    }

    /// At launch: back into a brew left unfinished.
    func resumeIfNeeded() {
        if module.hasBrewInProgress { start() }
    }

    // MARK: - Picker

    /// Picks `pick` for the setup and closes the picker; `added` items also get a toast.
    private func finishPicking(_ pick: GearPick, added name: String? = nil) {
        pickerSession?.deliver(pick)
        picker.close()
        pickerSession = nil
        if let name {
            toasts.show(tr("\(name) added"), style: .success)
        }
    }

    /// Pushes an add form into the picker sheet, opened to full height so the form fits. Pushed, it
    /// goes back with Back, so the Cancel its module adds for modal use is dropped.
    private func pushAddForm(_ form: UIViewController) {
        guard let sheet = picker.current else { return }
        form.navigationItem.leftBarButtonItem = nil
        if let presentation = sheet.navigationController.sheetPresentationController {
            presentation.animateChanges { presentation.selectedDetentIdentifier = .large }
        }
        sheet.push(form)
    }

    /// An add form opened from the picker finished: a new item is picked; otherwise (cancelled; delete
    /// and not-found can't happen, the forms only add) back to the list.
    private func finishAdding<Item>(_ result: FormResult<Item>, pick: (Item) -> GearPick, name: KeyPath<Item, String>) {
        if case .added(let item) = result {
            finishPicking(pick(item), added: item[keyPath: name])
        } else {
            picker.current?.pop()
        }
    }
}

extension BrewFlow: MethodPickRouting {
    func showMethods(in group: MethodGroup) {
        modal.current?.push(module.makeMethods(in: group, router: self))
    }

    func methodPickDidSelect(_ method: BrewMethod) {
        if method.isEspressoBased {
            modal.current?.push(module.makeEspressoSetup(method: method, router: self))
        } else {
            modal.current?.push(module.makeSetup(method: method, router: self))
        }
    }

    func methodPickDidCancel() {
        module.discardBrewInProgress()
        modal.close()
    }

    /// `AppRouter` closes the wizard, then opens the log sheet.
    func methodPickDidSelectLog() {
        module.discardBrewInProgress()
        logBrew()
    }
}

extension BrewFlow: GearPickerPresenting {
    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void) {
        guard let brewStack = modal.current, !picker.isPresented else { return }
        pickerSession = (method, onPick)
        picker.presentSheet(module.makeGearPicker(kind, method: method, selectedID: selectedID, router: self), over: brewStack, size: .resizable)
    }
}

// These refine other routing protocols; Swift 6 needs the isolation spelled out.
extension BrewFlow: @MainActor BrewSetupRouting {
    func brewSetupDidStart(_ setup: BrewSetup) {
        modal.current?.push(module.makeActiveBrew(setup: setup, router: self))
    }
}

extension BrewFlow: @MainActor EspressoRouting {
    func espresso(_ brew: EspressoBrew, didAdvanceTo step: EspressoStep) {
        modal.current?.push(module.makeEspressoStep(step, of: brew))
    }
}

extension BrewFlow: @MainActor BrewSavingRouting {
    /// The result becomes the only screen (no going back into a saved brew), with stock warnings.
    func brewDidSave(_ brew: Brew, usage: StockUsage) {
        module.discardBrewInProgress()
        modal.current?.setRoot(module.makeBrewResult(brew, router: self), animated: true)
        usage.warnings.forEach { toasts.show($0, style: .warning) }
    }
}

extension BrewFlow: BrewResultRouting {
    func brewResultDidTapJournal() {
        modal.close()
        showJournal()
    }

    func brewResultDidTapBrewAgain() {
        modal.current?.setRoot(module.makeMethodGroups(router: self), animated: true)
    }
}

extension BrewFlow: @MainActor ActiveBrewRouting {
    /// Rating replaces the timer, so Back from it doesn't return to a stopped timer.
    func activeBrewDidFinish(_ session: PourOverSession) {
        modal.current?.replaceTop(with: module.makeRateBrew(session: session, router: self))
    }

    /// Back on a started timer or the rating (confirmed): the brew is discarded.
    func brewDidDiscard() {
        module.discardBrewInProgress()
        modal.current?.pop()
    }
}

extension BrewFlow: GearPickerRouting {
    func gearPickerDidPick(_ pick: GearPick) {
        finishPicking(pick)
    }

    func gearPickerDidTapAdd(_ kind: GearKind) {
        switch kind {
        case .bean: pushAddForm(beansModule.makeAddBean(router: self))
        case .dripper: pushAddForm(devicesModule.makeAddDevice(type: .dripper, router: self))
        case .grinder: pushAddForm(devicesModule.makeAddDevice(type: .grinder, router: self))
        case .espressoMachine: pushAddForm(devicesModule.makeAddDevice(type: .espressoMachine, router: self))
        case .filter:
            let shape = pickerSession.flatMap { FilterShape.shapes(for: $0.method).first }
            pushAddForm(devicesModule.makeAddFilterPack(shape: shape, router: self))
        }
    }
}

extension BrewFlow: BeanFormRouting, DeviceFormRouting, FilterPackFormRouting {
    func beanForm(didFinish result: FormResult<Bean>) { finishAdding(result, pick: GearPick.bean, name: \.name) }
    func deviceForm(didFinish result: FormResult<Device>) { finishAdding(result, pick: GearPick.device, name: \.name) }
    func filterPackForm(didFinish result: FormResult<FilterPack>) { finishAdding(result, pick: GearPick.filterPack, name: \.name) }
}
