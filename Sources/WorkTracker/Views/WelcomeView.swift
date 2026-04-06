import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("WorkTracker")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accents[0], AppTheme.accents[4]],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Select a board or note to get started")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

#Preview {
    WelcomeView()
}
