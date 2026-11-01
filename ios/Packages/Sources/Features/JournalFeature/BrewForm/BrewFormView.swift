import SwiftUI
import Domain
import DesignSystem
import BrewKit

struct BrewFormView: View {
    @Bindable var viewModel: BrewFormViewModel

    var body: some View {
        LoadStateView(viewModel.state) {
            Task { await viewModel.load() }
        } content: {
            form
        }
        .task { await viewModel.load() }
        .errorAlert($viewModel.alertMessage)
    }

    private var brew: Brew { viewModel.brew }

    private var form: some View {
        Form {
            Section {
                LabeledContent(tr("Method"), value: brew.method.rawValue)
                if let bean = brew.bean {
                    LabeledContent(tr("Coffee"), value: bean.name)
                }
                DatePicker(tr("Date & time"), selection: $viewModel.brew.date, in: ...Date.now)
                    .accessibilityIdentifier("brewForm.date")
                if let place = viewModel.cafePlace {
                    TextField(tr("Café"), text: Binding(get: { place }, set: { viewModel.cafePlace = $0 }))
                        .textInputAutocapitalization(.words)
                }
            }
            .themedRow()

            Section(tr("Recipe")) {
                let isEspresso = viewModel.isEspresso
                NumberField(tr("Dose"), value: $viewModel.brew.doseGrams, unit: "g", range: isEspresso ? EspressoSetup.doseRange : BrewSetup.doseRange)
                    .accessibilityIdentifier("brewForm.dose")
                if isEspresso {
                    NumberField(tr("Yield"), value: $viewModel.actualYield, unit: "g", placeholder: decimal(brew.espresso?.targetYieldGrams ?? 0), range: 0...200)
                    NumberField(tr("Shot time"), value: $viewModel.shotTime, unit: tr("s"), range: 0...300, fractionDigits: 0)
                } else {
                    NumberField(tr("Ratio (1 : X)"), value: $viewModel.brew.ratio, range: BrewSetup.ratioRange)
                }
                if brew.isCafeVisit {
                    NumberField(tr("Volume"), value: $viewModel.brew.beverageVolume, unit: tr("ml"), range: 0...2_000, fractionDigits: 0)
                } else {
                    NumberField(tr("Temperature"), value: $viewModel.brew.waterTemperature, unit: "°C", range: 0...100, fractionDigits: 1)
                }
                if brew.grinder != nil {
                    NumberField(tr("Clicks"), value: $viewModel.grindSetting, range: 1...200, fractionDigits: 0)
                }
            }
            .themedRow()

            if !viewModel.isEspresso {
                steps
            }

            TastingSections(tasting: $viewModel.brew.tasting, notesPlaceholder: tr("Body, aftertaste, acidity…"))

            FormActions(
                title: tr("Save Changes"),
                isSaving: viewModel.isSaving,
                canSave: true,
                identifier: "brewForm",
                destructive: .init(tr("Delete Brew"), confirmation: tr("Delete this brew?"), confirmTitle: tr("Delete")) {
                    Task { await viewModel.delete() }
                }
            ) {
                Task { await viewModel.save() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .themedGroupedBackground()
        .accessibilityIdentifier("brewForm")
    }

    /// Pours and pauses (type, ml, seconds), swipe to remove, add at the end; the total below.
    private var steps: some View {
        Section {
            ForEach(Array(brew.steps.enumerated()), id: \.offset) { index, step in
                StepEditor(
                    step: step,
                    isPour: Binding(get: { viewModel.step(at: index)?.isPour ?? false }, set: { viewModel.setPour($0, at: index) }),
                    milliliters: Binding(
                        get: { viewModel.step(at: index)?.pouredMilliliters ?? 0 },
                        set: { value in viewModel.updateStep(at: index) { $0.kind = .pour(milliliters: max(value, 0)) } }
                    ),
                    seconds: Binding(
                        get: { viewModel.step(at: index)?.duration ?? 0 },
                        set: { value in viewModel.updateStep(at: index) { $0.duration = max(value, 0) } }
                    )
                )
            }
            .onDelete(perform: viewModel.removeSteps)
            Button(tr("Add Step"), systemImage: "plus") { viewModel.addStep() }
                .accessibilityIdentifier("brewForm.addStep")
        } header: {
            Text(tr("Steps"))
        } footer: {
            let steps = viewModel.savedSteps
            if !steps.isEmpty {
                let time = clockText(steps.last?.end ?? 0)
                let water = decimal(steps.totalPouredMilliliters)
                Text(tr("Total \(time) · \(water) ml"))
            }
        }
        .themedRow()
    }
}

/// One step: pour or pause (an action keeps its name), the ml of a pour and how long it took.
private struct StepEditor: View {
    let step: BrewStep
    @Binding var isPour: Bool
    @Binding var milliliters: Double
    @Binding var seconds: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if case .action = step.kind {
                Text(step.title).foregroundStyle(step.tint)
            } else {
                Picker(tr("Step"), selection: $isPour) {
                    Text(tr("Pour")).tag(true)
                    Text(tr("Pause")).tag(false)
                }
                .pickerStyle(.segmented)
            }
            if isPour {
                NumberField(tr("Water"), value: $milliliters, unit: tr("ml"), range: 0...2_000)
            }
            NumberField(tr("Time"), value: $seconds, unit: tr("s"), range: 0...3_600, fractionDigits: 0)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#if DEBUG
#Preview {
    BrewFormView(viewModel: BrewFormViewModel(brewID: Brew.samples[0].id, router: PreviewRouter.shared))
}
#endif
