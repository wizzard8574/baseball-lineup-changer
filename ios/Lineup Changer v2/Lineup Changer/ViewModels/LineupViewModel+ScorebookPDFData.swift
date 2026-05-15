// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+ScorebookPDFData.swift
//
//
//
// Scorebook PDF player data helpers.
import Foundation

// MARK: - Scorebook PDF Data
extension LineupViewModel {
    // MARK: - Player Text Helpers
    // Formats the player name for the scorebook lineup column.
    func scorebookLineupName(for player: Player) -> String {
        // Include the jersey number when available.
        if player.number.isEmpty {
            return player.name
        }
        return "#\(player.number) \(player.name)"
    }

    // Returns the player's current defensive position abbreviation for the scorebook.
    func scorebookPositionText(for player: Player) -> String {
        // Pitcher and catcher are stored separately, so check them first.
        if pitcherID == player.id {
            return "P"
        }
        if catcherID == player.id {
            return "C"
        }
        // Fall back to any position found in the current field lineup dictionary.
        if let assignedPosition = lineup.first(where: { $0.value == player.id })?.key {
            return assignedPosition.rawValue
        }
        return ""
    }
}
