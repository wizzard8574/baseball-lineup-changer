// Created by Rich Morris on 5/13/26.
// Lineup Changer
// BasketballLineupView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Basketball Lineup Screen Chrome
extension BasketballLineupView {
    var basketballLineupScreen: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        basketballLineupSections
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: "Lineup", systemImage: "basketball.fill")
                }
            }
            .sheet(isPresented: $isShowingBasketballLineupShareSheet) {
                if let basketballLineupShareURL {
                    ActivityView(activityItems: [basketballLineupShareURL])
                } else {
                    Text("No starting lineup file available.")
                }
            }
            .alert("Lineup Warning", isPresented: Binding(
                get: { !basketballLineupWarningMessage.isEmpty },
                set: { if !$0 { basketballLineupWarningMessage = "" } }
            )) {
                Button("OK", role: .cancel) {
                    basketballLineupWarningMessage = ""
                }
            } message: {
                Text(basketballLineupWarningMessage)
            }
            .confirmationDialog(
                "Choose Player to Replace",
                isPresented: $isShowingBasketballReplacementChoices,
                titleVisibility: .visible
            ) {
                if let pendingBasketballBenchPlayer {
                    ForEach(BasketballPosition.allCases.filter { pendingBasketballBenchPlayer.basketballPositionRatings[$0] != nil }) { position in
                        Button(basketballReplacementOptionLabel(for: position, benchPlayer: pendingBasketballBenchPlayer)) {
                            replaceBasketballStarter(with: pendingBasketballBenchPlayer, at: position)
                            self.pendingBasketballBenchPlayer = nil
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    pendingBasketballBenchPlayer = nil
                }
            } message: {
                if let pendingBasketballBenchPlayer {
                    Text("Where should \(basketballLineupDisplayLabel(for: pendingBasketballBenchPlayer)) enter the game?")
                }
            }
            .confirmationDialog(
                "Choose Bench Replacement",
                isPresented: $isShowingBasketballStarterReplacementChoices,
                titleVisibility: .visible
            ) {
                if let pendingBasketballStarterPosition {
                    ForEach(viewModel.basketballBenchPlayersRated(for: pendingBasketballStarterPosition)) { benchPlayer in
                        Button(basketballStarterReplacementOptionLabel(for: benchPlayer, at: pendingBasketballStarterPosition)) {
                            replaceBasketballStarter(with: benchPlayer, at: pendingBasketballStarterPosition)
                            pendingBasketballStarterPlayer = nil
                            self.pendingBasketballStarterPosition = nil
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    pendingBasketballStarterPlayer = nil
                    pendingBasketballStarterPosition = nil
                }
            } message: {
                if let pendingBasketballStarterPlayer,
                   let pendingBasketballStarterPosition {
                    Text("Who should replace \(basketballLineupDisplayLabel(for: pendingBasketballStarterPlayer)) at position \(pendingBasketballStarterPosition.rawValue)?")
                }
            }
            .onAppear {
                viewModel.syncBasketballLineup(autoAssignIfDefaultOrder: true)
            }
        }
    }
}
