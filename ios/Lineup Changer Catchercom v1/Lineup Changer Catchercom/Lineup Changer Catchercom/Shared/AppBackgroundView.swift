import SwiftUI

struct AppBackgroundView: View {
    // MARK: - Body

    var body: some View {
        ZStack {
            // Shared game-day background used behind every tab.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.blue.opacity(0.38),
                    Color.yellow.opacity(0.30),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.blue.opacity(0.32))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -180, y: -260)

            Circle()
                .fill(Color.yellow.opacity(0.24))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: 190, y: -120)

            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: -150, y: 320)

            Circle()
                .fill(Color.yellow.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: 170, y: 360)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear,
                    Color.white.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

extension View {
    // MARK: - Screen Styling

    func appScreenBackground() -> some View {
        background(AppBackgroundView())
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
