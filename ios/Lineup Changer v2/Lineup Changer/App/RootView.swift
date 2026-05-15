import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    @AppStorage("hasSelectedInitialSport") private var hasSelectedInitialSport = false
    @StateObject private var viewModel = LineupViewModel()

    var body: some View {
        ZStack {
            ContentView(viewModel: viewModel)

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if !hasSelectedInitialSport && !showSplash {
                InitialSportSelectionView(viewModel: viewModel) {
                    hasSelectedInitialSport = true
                }
                .zIndex(3)
            }
        }
        .onAppear(perform: showLaunchSplash)
    }

    private func showLaunchSplash() {
        showSplash = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.35)) {
                showSplash = false
            }
        }
    }
}
