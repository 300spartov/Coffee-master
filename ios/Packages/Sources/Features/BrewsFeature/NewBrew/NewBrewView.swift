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
                    ForEach(BrewMethod.allCases, id: \.self) { method in
                        Text(method.title).tag(method)
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
                Picker("Rating", selection: $viewModel.rating) {
                    ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
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
    NewBrewView(viewModel: NewBrewViewModel(repository: PreviewBrewRepository(), router: PreviewRouter.shared))
}
#endif
