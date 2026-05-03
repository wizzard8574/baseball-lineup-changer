import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("SplashScreen")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()
        }
    }
}

enum MainTab: Hashable {
    case field
    case lineup
    case players
    case notes
    case settings
}

struct ContentView: View {
    @StateObject private var viewModel = LineupViewModel()
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
