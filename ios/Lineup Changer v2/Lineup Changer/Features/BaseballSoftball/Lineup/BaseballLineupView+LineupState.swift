// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+LineupState.swift
//
//
//
import SwiftUI

// MARK: - Lineup State
extension BaseballLineupView {
    var battingOrderBatters: [Player] {
        viewModel.baseballDisplayedBatters
    }

    var displayedBatters: [Player] {
        viewModel.baseballDisplayedBattersForLineup
    }

    var benchBatters: [Player] {
        viewModel.baseballBenchBatters
    }

    var shouldShowLineupCountWarning: Bool {
        viewModel.baseballUsesNineBatterAndDH && viewModel.baseballLineupLimitWarningText != nil
    }

    var lineupCountWarningText: String {
        viewModel.baseballLineupLimitWarningText ?? "You can't add more than 9 to the lineup"
    }

    func isDesignatedHitterRow(index: Int, player: Player) -> Bool {
        guard viewModel.baseballUsesNineBatterAndDH,
              player.id == viewModel.designatedHitterID,
              battingOrderBatters.indices.contains(index) else { return false }

        return battingOrderBatters[index].id == viewModel.designatedHitterForID
    }

    func designatedHitterForText(at index: Int) -> String? {
        guard viewModel.baseballUsesNineBatterAndDH,
              battingOrderBatters.indices.contains(index),
              battingOrderBatters[index].id == viewModel.designatedHitterForID else { return nil }

        return "DH for \(lineupDisplayLabel(for: battingOrderBatters[index]))"
    }

    func assignedFieldPositionLabel(for player: Player) -> String? {
        guard viewModel.baseballUsesNineBatterAndDH,
              let assignedPosition = FieldPosition.allCases.first(where: { viewModel.lineup[$0] == player.id }) else { return nil }

        return assignedPosition.rawValue
    }

    func battingOrderBadgeText(index: Int, player: Player) -> String {
        if let fieldPositionLabel = assignedFieldPositionLabel(for: player) {
            return "\(index + 1)-\(fieldPositionLabel)"
        }

        return "\(index + 1)"
    }

    func hasSlowPitcherCatcherWarning(at index: Int) -> Bool {
        guard viewModel.showSlowSpeedBattingWarnings,
              index > 0,
              battingOrderBatters.indices.contains(index),
              battingOrderBatters.indices.contains(index - 1) else { return false }

        let currentPlayer = battingOrderBatters[index]
        let previousPlayer = battingOrderBatters[index - 1]
        let isPitcherOrCatcher = currentPlayer.id == viewModel.pitcherID || currentPlayer.id == viewModel.catcherID

        return isPitcherOrCatcher && currentPlayer.speedRating == 2 && previousPlayer.speedRating == 2
    }

    func warningText(for player: Player) -> String {
        let role: String
        if player.id == viewModel.pitcherID {
            role = "pitcher"
        } else if player.id == viewModel.catcherID {
            role = "catcher"
        } else {
            role = "player"
        }

        return "Warning: No Steal \(role) bats after a No Steal runner"
    }
}
