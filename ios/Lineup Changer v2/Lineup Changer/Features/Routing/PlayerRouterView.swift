// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayerRouterView.swift
//
//
//
// PlayerRouterView routes the Players tab to the selected sport's roster screen.
import SwiftUI

// MARK: - Player Router View
// Small sport router for the Players tab.
struct PlayerRouterView: View {
    // Shared roster, coach, team, and sport state.
    @ObservedObject var viewModel: LineupViewModel

    // MARK: - Body
    // Shows the selected sport's roster UI or a shared placeholder for unsupported sports.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            BaseballPlayersView(viewModel: viewModel)
        case .basketball:
            BasketballPlayersView(viewModel: viewModel)
        case .football, .volleyball, .soccer:
            playerPlaceholderView
        }
    }

    private var playerPlaceholderView: some View {
        SportFeaturePlaceholderView(
            title: viewModel.selectedSport.playersPlaceholderTitle,
            message: viewModel.selectedSport.playersPlaceholderMessage,
            toolbarTitle: "Players",
            toolbarIconName: "person.3.fill",
            symbolName: "person.3"
        )
    }
}
