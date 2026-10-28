import SwiftUI
import DesignSystem

/// Static screen — no ViewModel needed. Add one only when a screen has state or logic.
struct AboutView: View {
    let appVersion: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brandPrimary)
            Text("Coffee Master")
                .font(.title.bold())
            Text("Notes, recipes and stats for your coffee.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Version \(appVersion)")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutView(appVersion: "1.0 (1)")
}
