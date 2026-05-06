// Created by Rich Morris on 5/5/26.
// Lineup Changer
// ContentView.swift
//
//
//
// Entry-point UI for the app's main screen flow.
// This file contains the splash screen, first-run sport selection screen,
// shared background styling, and the primary tab-based ContentView.
import SwiftUI

// MARK: - Root Launch Flow
// Root container shown when the app launches.
// It owns the shared LineupViewModel, displays the splash screen first,
// and presents the initial sport picker until the user chooses a sport.
struct RootView: View {
    // Controls whether the launch splash overlay is visible.
    @State private var showSplash = true
    // Persists whether the user has completed the first-run sport selection.
    @AppStorage("hasSelectedInitialSport") private var hasSelectedInitialSport = false
    // Single shared view model instance used by the app's main views.
    @StateObject private var viewModel = LineupViewModel()

    // Main launch flow: app content at the back, temporary overlays above it.
    var body: some View {
        ZStack {
            // Main app UI remains mounted behind the splash and first-run screens.
            ContentView(viewModel: viewModel)

            // Splash screen appears briefly on launch and fades away.
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(2)
            }

            // After the splash, force new users to choose their starting sport.
            if !hasSelectedInitialSport && !showSplash {
                SportSelectionView(viewModel: viewModel) {
                    hasSelectedInitialSport = true
                }
                .zIndex(3)
            }
        }
        .onAppear {
            // Reset and show the splash whenever the root view appears.
            showSplash = true

            // Keep the splash on screen long enough to be seen, then fade it out.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}
// MARK: - Splash Screen
// Full-screen launch splash overlay.
// Uses the SplashScreen image asset with a subtle scale/opacity animation.
struct SplashScreenView: View {
    // Drives the splash image's entrance animation.
    @State private var animateIn = false
    // Splash artwork layered over a black background with a light vignette.
    var body: some View {
        ZStack {
            // Black base prevents any bright flash while the splash image loads.
            Color.black.ignoresSafeArea()

            // Main splash artwork.
            Image("SplashScreen")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .scaleEffect(animateIn ? 1.04 : 1.0)
                .opacity(animateIn ? 1.0 : 0.92)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 1.6), value: animateIn)

            // Subtle top/bottom shading for better contrast on varied devices.
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
            // Start the image animation once the splash is on screen.
            animateIn = true
        }
    }
}

// MARK: - First-Run Sport Selection
// First-run sport picker shown after the splash screen.
// Baseball/softball is currently enabled; the other sports are shown as disabled
// placeholders for future support.
struct SportSelectionView: View {
    // Shared app state that stores the selected sport.
    @ObservedObject var viewModel: LineupViewModel
    // Callback used by RootView to mark first-run sport selection complete.
    let onSportSelected: () -> Void
    // Reserved animation state for the picker screen.
    @State private var animateIn = false
    // Tracks the sport tapped by the user so the button can show selection feedback.
    @State private var selectedSport: SportType?

    // Full-screen sport selection artwork with the button bar anchored at the bottom.
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background artwork sized to the current device dimensions.
                Image("LaunchScreen")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // Darkens the lower portion so the sport buttons remain readable.
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

                    // Sport choices are grouped into one pill-shaped control bar.
                    sportButtonBar
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom + 18, 34))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(10)
            }
        }
        .onAppear {
            // Marks the picker as visible for any future entrance animation.
            animateIn = true
        }
    }

    // MARK: - Sport Button Helpers
    // Horizontal list of sport buttons.
    // Disabled sports are still visible so users can see future app direction.
    private var sportButtonBar: some View {
        HStack(spacing: 10) {
            // Baseball/softball is the only selectable sport at this point.
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

    // Builds a circular sport icon button with selected/disabled visual states.
    private func sportButton(_ sport: SportType, _ icon: String, isEnabled: Bool = true) -> some View {
        Button {
            // Ignore taps on sports that are not implemented yet.
            guard isEnabled else { return }

            // Record selection immediately so the button can visually respond.
            selectedSport = sport

            // Brief spring animation gives the selected button a tap response.
            withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                selectedSport = sport
            }

            // Delay committing the selection slightly so the selection animation is visible.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                viewModel.selectedSport = sport
                viewModel.save()
                onSportSelected()
            }
        } label: {
            // Emoji icon acts as the visual representation for each sport.
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

// MARK: - Main Tab Model
// Tabs available in the main app interface.
// Hashable conformance allows these cases to be used as TabView selection tags.
enum MainTab: Hashable {
    case field
    case lineup
    case players
    case notes
    case settings
}

// MARK: - Shared Background
// Reusable sports-themed background made from gradients and blurred color circles.
struct AppSportsBackground: View {
    // Layered background used where the app needs a branded sports-style backdrop.
    var body: some View {
        ZStack {
            // Base diagonal gradient.
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

            // Large blurred circles add soft blue/yellow lighting effects.
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

            // Light overlay adds depth and keeps the background from looking flat.
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

// MARK: - Main Content View
// Primary tab-based app interface shown after launch.
// Each tab receives the same shared LineupViewModel so data stays consistent
// across field assignments, lineup order, players, notes, and settings.
struct ContentView: View {
    // Shared state and business logic for all tab screens.
    @ObservedObject var viewModel: LineupViewModel
    // Currently selected main tab.
    @State private var selectedTab: MainTab = .field

    // Main tab layout for the app's core sections.
    var body: some View {
        TabView(selection: $selectedTab) {
            // Field assignment screen.
            AssignmentView(viewModel: viewModel)
                .tabItem {
                    Label("Field", systemImage: "baseball.diamond.bases")
                }
                .tag(MainTab.field)

            // Batting/lineup order screen.
            LineupOrderView(viewModel: viewModel)
                .tabItem {
                    Label("Lineup", systemImage: "list.number")
                }
                .tag(MainTab.lineup)

            // Player roster management screen.
            PlayerListView(viewModel: viewModel)
                .tabItem {
                    Label("Players", systemImage: "person.3")
                }
                .tag(MainTab.players)

            // Team notes screen.
            NotesView(viewModel: viewModel)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(MainTab.notes)

            // App settings and import/export tools.
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(MainTab.settings)
        }
        .onAppear {
            // On first use with no players, start on Players so the user can build a roster.
            selectedTab = viewModel.players.isEmpty ? .players : .field
        }
    }
}

// MARK: - Preview
// Xcode preview for the full root launch flow.
#Preview {
    RootView()
}
