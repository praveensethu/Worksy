import SwiftUI

struct WelcomeView: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            // Subtle animated background gradient
            RadialGradient(
                colors: [
                    AppTheme.accents[0].opacity(0.08),
                    AppTheme.accents[2].opacity(0.05),
                    Color.clear
                ],
                center: animateGradient ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)

            VStack(spacing: 24) {
                Spacer()

                // App icon representation
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.background)
                        .frame(width: 120, height: 120)
                        .shadow(color: AppTheme.accents[0].opacity(0.3), radius: 20, x: 0, y: 0)

                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#FFB800"))  // Amber
                            .frame(width: 22, height: 50)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#FF6B6B"))  // Coral
                            .frame(width: 22, height: 40)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#00D68F"))  // Emerald
                            .frame(width: 22, height: 30)
                    }
                }

                Text("Worksy")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFB800"), Color(hex: "#FF6B6B")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Select a board or note to get started")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                // Keyboard shortcut hints
                VStack(spacing: 10) {
                    Text("KEYBOARD SHORTCUTS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                        .tracking(1.5)

                    HStack(spacing: 24) {
                        shortcutHint(keys: "Cmd + N", action: "New Board")
                        shortcutHint(keys: "Cmd + ,", action: "Preferences")
                        shortcutHint(keys: "Cmd + W", action: "Close Window")
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            animateGradient = true
        }
    }

    @ViewBuilder
    private func shortcutHint(keys: String, action: String) -> some View {
        VStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppTheme.textMuted.opacity(0.3), lineWidth: 1)
                )
            Text(action)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textMuted)
        }
    }
}

#Preview {
    WelcomeView()
}
