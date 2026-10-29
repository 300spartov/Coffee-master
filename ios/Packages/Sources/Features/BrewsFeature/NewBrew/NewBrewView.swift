import SwiftUI
import Domain
import DesignSystem

struct NewBrewView: View {
    @Bindable var viewModel: NewBrewViewModel

    var body: some View {
        Form {
            Section(tr("Coffee")) {
                TextField(tr("Bean name"), text: $viewModel.beanName)
                    .textInputAutocapitalization(.words)
                Picker(tr("Method"), selection: $viewModel.method) {
                    ForEach(BrewMethod.formPresets, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
            }

            Section(tr("Recipe")) {
                Stepper(value: $viewModel.doseGrams, in: 5...40, step: 0.5) {
                    LabeledContent(tr("Dose"), value: "\(viewModel.doseGrams.formatted()) g")
                }
                Stepper(value: $viewModel.waterGrams, in: 20...1_000, step: 10) {
                    LabeledContent(tr("Water"), value: "\(viewModel.waterGrams.formatted()) g")
                }
                Stepper(value: $viewModel.brewTime, in: 10...600, step: 5) {
                    LabeledContent(
                        tr("Time"),
                        value: Duration.seconds(viewModel.brewTime).formatted(.time(pattern: .minuteSecond))
                    )
                }
            }

            Section(tr("Rating")) {
                LabeledContent(tr("Rating"), value: viewModel.rating.formatted(.number.precision(.fractionLength(1))))
                Slider(value: $viewModel.rating, in: Brew.ratingRange, step: 0.5)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.theme.error)
                }
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text(tr("Save"))
                    }
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.isValid || viewModel.isSaving)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }
}

#if DEBUG
#Preview {
    NewBrewView(viewModel: NewBrewViewModel(router: PreviewRouter.shared))
}
#endif
