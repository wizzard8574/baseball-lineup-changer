// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView+StatusActions.swift
//
//
//
import SwiftUI

// MARK: - Baseball Players Status Actions
extension BaseballPlayersView {
    @ViewBuilder
    func statusButtons(for player: Player) -> some View {
        if player.status != .unavailable {
            Button("Unavailable") {
                viewModel.setPlayerStatus(playerID: player.id, status: .unavailable)
            }
            .tint(.orange)
        }

        if player.status != .injured {
            Button("Injured") {
                viewModel.setPlayerStatus(playerID: player.id, status: .injured)
            }
            .tint(.red)
        }

        if player.status != .guest {
            Button("Guest") {
                viewModel.setPlayerStatus(playerID: player.id, status: .guest)
            }
            .tint(.blue)
        }

        if player.status != .active {
            Button("Active") {
                viewModel.setPlayerStatus(playerID: player.id, status: .active)
            }
            .tint(.green)
        }
    }
}
