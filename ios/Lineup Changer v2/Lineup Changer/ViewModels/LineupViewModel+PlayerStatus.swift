// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+PlayerStatus.swift
//
//
//
// Player status updates and related assignment cleanup.
import Foundation

// MARK: - Player Status Updates
extension LineupViewModel {
    // Updates active/guest/injured/unavailable status and cleans up assignments when needed.
    func setPlayerStatus(playerID: UUID, status: PlayerStatus) {
        // Ignore status changes for players no longer in the roster.
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        // Replace the value-type Player so SwiftUI observes the status update.
        var refreshedPlayer = players[index]
        refreshedPlayer.status = status
        players[index] = refreshedPlayer

        // Non-active players should not remain in field, lineup, or DH assignments.
        if status != .active {
            // Clear current role assignments for the removed player.
            if pitcherID == playerID { pitcherID = nil }
            if catcherID == playerID { catcherID = nil }
            if designatedHitterID == playerID { designatedHitterID = nil }
            if designatedHitterForID == playerID { designatedHitterForID = nil }

            // Remove the player from the current field lineup.
            lineup = lineup.filter { _, assignedPlayerID in
                assignedPlayerID != playerID
            }

            // Remove the player from every saved inning lineup.
            for inning in Array(inningLineups.keys) {
                inningLineups[inning] = inningLineups[inning]?.filter { _, assignedPlayerID in
                    assignedPlayerID != playerID
                } ?? [:]
            }

            // Remove the player from saved inning pitcher assignments.
            for inning in Array(inningPitcherIDs.keys) where inningPitcherIDs[inning] == playerID {
                inningPitcherIDs.removeValue(forKey: inning)
            }

            // Remove the player from saved inning catcher assignments.
            for inning in Array(inningCatcherIDs.keys) where inningCatcherIDs[inning] == playerID {
                inningCatcherIDs.removeValue(forKey: inning)
            }
        }

        // Keep batting order and saved inning state aligned with the updated roster.
        syncBattingOrder()
        saveCurrentInningState()
        save()
    }
}
