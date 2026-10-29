import SwiftUI
import Domain
import DesignSystem

struct BrewDetailView: View {
    let viewModel: BrewDetailViewModel
    @State private var isConfirmingDelete = false

    var body: some View {
        content
            .task { await viewModel.load() }
            .alert(
                tr("Error"),
                isPresented: Binding(
                    get: { viewModel.alertMessage != nil },
                    set: { if !$0 { viewModel.alertMessage = nil } }
                ),
                presenting: viewModel.alertMessage
            ) { _ in
                Button(tr("OK"), role: .cancel) {}
            } message: { message in
                Text(message)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingView()
        case .failed(let message):
            ErrorStateView(message: message)
        case .loaded(let brew):
            details(for: brew)
        }
    }

    private func details(for brew: Brew) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header(for: brew)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                    StatTile(title: tr("Dose"), value: "\(brew.doseGrams.formatted()) g")
                    StatTile(title: tr("Water"), value: "\(brew.waterGrams.formatted()) g")
                    StatTile(title: tr("Ratio"), value: "1:\(brew.ratio.formatted(.number.precision(.fractionLength(1))))")
                    StatTile(title: tr("Time"), value: brew.totalTime.map { Duration.seconds($0).formatted(.time(pattern: .minuteSecond)) } ?? "—")
                }

                VStack(spacing: Spacing.md) {
                    Button {
                        Task { await viewModel.toggleTimer() }
                    } label: {
                        Label(
                            viewModel.isTimerRunning ? tr("Stop Timer") : tr("Start Brew Timer"),
                            systemImage: viewModel.isTimerRunning ? "stop.fill" : "timer"
                        )
                    }
                    .buttonStyle(.primary)

                    Button(tr("Delete Brew"), role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .foregroundStyle(.theme.error)
                }
            }
            .padding(Spacing.lg)
        }
        .themedGroupedBackground()
        .confirmationDialog(tr("Delete this brew?"), isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button(tr("Delete"), role: .destructive) {
                Task { await viewModel.delete() }
            }
        }
    }

    private func header(for brew: Brew) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(brew.method.rawValue, systemImage: brew.method.systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.theme.accent)
            Text(brew.displayTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(.theme.textPrimary)
            HStack {
                RatingView(rating: brew.rating)
                Spacer()
                Text(brew.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.theme.textSecondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    // Previews resolve the default (fixture) registrations — no setup needed.
    BrewDetailView(viewModel: BrewDetailViewModel(brewID: Brew.samples[0].id, router: PreviewRouter.shared))
}
#endif
