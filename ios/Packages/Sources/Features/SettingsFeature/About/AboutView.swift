import SwiftUI
import DesignSystem

/// Static screen — no ViewModel needed. Add one only when a screen has state or logic.
struct AboutView: View {
    let appVersion: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 64))
                .foregroundStyle(.theme.accent)
            Text("Coffee Master")
                .font(.title.bold())
                .foregroundStyle(.theme.textPrimary)
            Text("Notes, recipes and stats for your coffee.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.theme.textSecondary)
            Text("Version \(appVersion)")
                .font(.footnote)
                .foregroundStyle(.theme.textTertiary)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }
}

#Preview {
    AboutView(appVersion: "1.0 (1)")
}
