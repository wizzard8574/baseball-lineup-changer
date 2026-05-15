import SwiftUI

struct SplashScreenView: View {
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("SplashScreen")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .scaleEffect(animateIn ? 1.04 : 1.0)
                .opacity(animateIn ? 1.0 : 0.92)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 1.6), value: animateIn)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.clear,
                    Color.black.opacity(0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onAppear {
            animateIn = true
        }
    }
}
