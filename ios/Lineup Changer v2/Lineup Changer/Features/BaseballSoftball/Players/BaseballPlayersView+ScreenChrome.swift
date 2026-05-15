// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Baseball Players Screen Chrome
extension BaseballPlayersView {
    var playersScreen: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                List {
                    playersListSections
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                playersToolbar
            }
            .navigationDestination(item: $newPlayerDraft) { player in
                BaseballPlayerDetailView(viewModel: viewModel, player: player)
            }
            .navigationDestination(item: $newCoachDraft) { coach in
                CoachDetailView(viewModel: viewModel, coach: coach)
            }
        }
    }

    @ToolbarContentBuilder
    private var playersToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            playersTitle
        }

        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
        }
    }
}
