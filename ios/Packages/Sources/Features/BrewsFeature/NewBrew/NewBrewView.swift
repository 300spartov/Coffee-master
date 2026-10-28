import SwiftUI
import Domain
import DesignSystem

struct NewBrewView: View {
    @Bindable var viewModel: NewBrewViewModel

    var body: some View {
        Form {
            Section("Coffee") {
                TextField("Bean name", text: $viewModel.beanName)
                    .textInputAutocapitalization(.words)
                Picker("Method", selection: $viewModel.method) {
                    ForEach(BrewMethod.formPresets, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
            }

            Section("Recipe") {
                Stepper(value: $viewModel.doseGrams, in: 5...40, step: 0.5) {
                    LabeledContent("Dose", value: "\(viewModel.doseGrams.formatted()) g")
                }
                Stepper(value: $viewModel.waterGrams, in: 20...1_000, step: 10) {
                    LabeledContent("Water", value: "\(viewModel.waterGrams.formatted()) g")
                }
                Stepper(value: $viewModel.brewTime, in: 10...600, step: 5) {
                    LabeledContent(
                        "Time",
                        value: Duration.seconds(viewModel.brewTime).formatted(.time(pattern: .minuteSecond))
                    )
                }
            }

            Section("Rating") {
                LabeledContent("Rating", value: viewModel.rating.formatted(.number.precision(.fractionLength(1))))
                Slider(value: $viewModel.rating, in: Brew.ratingRange, step: 0.5)
                    .tint(.theme.accent)
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
                        Text("Save")
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
