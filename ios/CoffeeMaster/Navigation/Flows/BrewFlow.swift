import UIKit
import FactoryKit
import Domain
import DesignSystem
import Navigation
import BrewFeature
import BrewsFeature
import BeansFeature
import DevicesFeature

/// The brew action's modal flow, presented full screen over the tabs: the brew wizard.
/// Pour-over: method pick (2.1) → setup (2.2) → brew timer (2.3) → the template "New Brew" form, until
/// rating (2.7) replaces it. Espresso (2.5): setup → shot → milk / ice → result, saved there.
///
/// Setup rows open a picker sheet; its "+" pushes the Beans / Devices add forms into the sheet, so a
/// missing bag or device can be added without leaving the brew.
final class BrewFlow {
    private let module: BrewModule
    private let brewsModule: BrewsModule
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

    init(module: BrewModule, brewsModule: BrewsModule, beansModule: BeansModule, devicesModule: DevicesModule, presenter: UIViewController) {
        self.module = module
        self.brewsModule = brewsModule
        self.beansModule = beansModule
        self.devicesModule = devicesModule
        self.presenter = presenter
    }

    /// Whether the brew screen is really still on screen (`AppRouter` may have dismissed it for a deep link).
    var isPresented: Bool { modal.isPresented }

    func start() {
        guard let presenter else { return }
        modal.present {
            StackRouter.presentStack(root: module.makeMethodGroups(router: self), from: presenter, style: .fullScreen)
        }
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

    /// The add form was cancelled (or something unexpected happened): back to the list.
    private func backToPicker() {
        picker.current?.pop()
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
        modal.close()
    }
}

extension BrewFlow: GearPickerPresenting {
    func showGearPicker(_ kind: GearKind, method: BrewMethod, selectedID: UUID?, onPick: @escaping (GearPick) -> Void) {
        guard let brewStack = modal.current else { return }
        picker.present {
            pickerSession = (method, onPick)
            return brewStack.presentStack(root: module.makeGearPicker(kind, method: method, selectedID: selectedID, router: self)) { sheet in
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
    }

}

// These two refine `GearPickerPresenting` (conformed above); Swift 6 needs the isolation spelled out.
extension BrewFlow: @MainActor BrewSetupRouting {
    func brewSetupDidStart(_ setup: BrewSetup) {
        modal.current?.push(module.makeActiveBrew(setup: setup, router: self))
    }
}

extension BrewFlow: @MainActor EspressoRouting {
    func espresso(_ brew: EspressoBrew, didAdvanceTo step: EspressoStep) {
        modal.current?.push(module.makeEspressoStep(step, of: brew))
    }

    func espressoDidSave(_ brew: Brew) {
        modal.close()
        toasts.show(tr("Shot saved"), style: .success)
    }
}

extension BrewFlow: ActiveBrewRouting {
    /// The finished brew replaces the timer, so Back from the form doesn't return to a stopped timer.
    func activeBrewDidFinish(_ session: PourOverSession) {
        let form = brewsModule.makeNewBrew(setup: session.setup, steps: session.steps, totalTime: session.elapsed(at: .now), router: self)
        modal.current?.replaceTop(with: form)
    }

    func activeBrewDidLeave() {
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

// Add forms opened from the picker. They only add, so delete / not-found can't happen here.

extension BrewFlow: BeanFormRouting {
    func beanFormDidFinish(saved bean: Bean?) {
        if let bean { finishPicking(.bean(bean), added: bean.name) } else { backToPicker() }
    }

    func beanFormDidDelete(id: Bean.ID) { backToPicker() }
    func beanFormNotFound(id: Bean.ID) { backToPicker() }
}

extension BrewFlow: DeviceFormRouting {
    func deviceFormDidFinish(saved device: Device?) {
        if let device { finishPicking(.device(device), added: device.name) } else { backToPicker() }
    }

    func deviceFormDidDelete(id: Device.ID) { backToPicker() }
    func deviceFormNotFound(id: Device.ID) { backToPicker() }
}

extension BrewFlow: FilterPackFormRouting {
    func filterPackFormDidFinish(saved pack: FilterPack?) {
        if let pack { finishPicking(.filterPack(pack), added: pack.name) } else { backToPicker() }
    }

    func filterPackFormDidDelete(id: FilterPack.ID) { backToPicker() }
    func filterPackFormNotFound(id: FilterPack.ID) { backToPicker() }
}

extension BrewFlow: NewBrewRouting {
    func newBrewDidSave(_ brew: Brew) {
        modal.close()
        toasts.show(tr("Brew saved"), style: .success)
    }
}
