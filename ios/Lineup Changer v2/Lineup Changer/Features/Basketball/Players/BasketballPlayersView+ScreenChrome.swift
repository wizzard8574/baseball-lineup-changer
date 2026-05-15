// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayersView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Basketball Players Screen Chrome
extension BasketballPlayersView {
    var basketballPlayersScreen: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                basketballPlayersList
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    basketballTitle
                }

                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .navigationDestination(item: $newPlayerDraft) { player in
                BasketballPlayerDetailView(viewModel: viewModel, player: player)
            }
            .navigationDestination(item: $newCoachDraft) { coach in
                CoachDetailView(viewModel: viewModel, coach: coach)
            }
        }
    }
}
