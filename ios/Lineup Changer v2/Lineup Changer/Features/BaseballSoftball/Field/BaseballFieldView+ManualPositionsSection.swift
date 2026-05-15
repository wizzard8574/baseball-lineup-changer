// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+ManualPositionsSection.swift
//
//
//
import SwiftUI

// MARK: - Manual Positions Section
extension BaseballFieldView {
    var manualPositionsSection: some View {
        Section(header: fieldSectionHeader("Manual Positions")) {
            if !viewModel.fallBallEnabled {
                Picker("Pitcher", selection: Binding(
                    get: { viewModel.pitcherID },
                    set: { updatePitcherSelection($0) }
                )) {
                    Text("Choose pitcher").tag(UUID?.none)
                    ForEach(sortedActivePlayers) { player in
                        Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                    }
                }
            }

            if !viewModel.fallBallRunRuleEnabled {
                Picker("Catcher", selection: Binding(
                    get: { viewModel.catcherID },
                    set: { updateCatcherSelection($0) }
                )) {
                    Text("Choose catcher").tag(UUID?.none)
                    ForEach(catcherPickerPlayers) { player in
                        Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                    }
                }
            }
        }
    }
}
