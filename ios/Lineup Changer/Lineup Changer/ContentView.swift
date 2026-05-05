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
                SportSelectionView(viewModel: viewModel) {
                    hasSelectedInitialSport = true
                }
                .zIndex(3)
            }
        }
        .onAppear {
            showSplash = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}
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

struct SportSelectionView: View {
    @ObservedObject var viewModel: LineupViewModel
    let onSportSelected: () -> Void
    @State private var animateIn = false
    @State private var selectedSport: SportType?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("LaunchScreen")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.05),
                        Color.clear,
                        Color.black.opacity(0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    sportButtonBar
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom + 18, 34))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(10)
            }
        }
        .onAppear {
            animateIn = true
        }
    }

    private var sportButtonBar: some View {
        HStack(spacing: 10) {
            sportButton(.baseballSoftball, "⚾️")
            sportButton(.basketball, "🏀", isEnabled: false)
            sportButton(.football, "🏈", isEnabled: false)
            sportButton(.volleyball, "🏐", isEnabled: false)
            sportButton(.soccer, "⚽️", isEnabled: false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.black.opacity(0.72), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.55), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.85), radius: 28, x: 0, y: 12)
    }

    private func sportButton(_ sport: SportType, _ icon: String, isEnabled: Bool = true) -> some View {
        Button {
            guard isEnabled else { return }

            selectedSport = sport

            withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                selectedSport = sport
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                viewModel.selectedSport = sport
                viewModel.save()
                onSportSelected()
            }
        } label: {
            Text(icon)
                .font(.system(size: 31))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(selectedSport == sport ? 0.18 : 0.06))
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(selectedSport == sport ? 0.9 : 0.28), lineWidth: selectedSport == sport ? 2 : 1)
                )
                .shadow(color: .white.opacity(selectedSport == sport ? 0.45 : 0.12), radius: selectedSport == sport ? 14 : 5)
                .shadow(color: .black.opacity(0.35), radius: 7, x: 0, y: 4)
                .scaleEffect(selectedSport == sport ? 1.12 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
    }
}

enum MainTab: Hashable {
    case field
    case lineup
    case players
    case notes
    case settings
}

struct AppSportsBackground: View {
    var body: some View {
        ZStack {
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

struct ContentView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State private var selectedTab: MainTab = .field

    var body: some View {
        TabView(selection: $selectedTab) {
            AssignmentView(viewModel: viewModel)
                .tabItem {
                    Label("Field", systemImage: "baseball.diamond.bases")
                }
                .tag(MainTab.field)

            LineupOrderView(viewModel: viewModel)
                .tabItem {
                    Label("Lineup", systemImage: "list.number")
                }
                .tag(MainTab.lineup)

            PlayerListView(viewModel: viewModel)
                .tabItem {
                    Label("Players", systemImage: "person.3")
                }
                .tag(MainTab.players)

            NotesView(viewModel: viewModel)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(MainTab.notes)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(MainTab.settings)
        }
        .onAppear {
            selectedTab = viewModel.players.isEmpty ? .players : .field
        }
    }
}

#Preview {
    RootView()
}
