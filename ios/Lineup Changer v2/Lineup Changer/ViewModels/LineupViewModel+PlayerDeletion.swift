// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+PlayerDeletion.swift
//
//
//
// Player deletion and bulk roster reset helpers.
import Foundation
import SwiftUI

// MARK: - Delete Players
extension LineupViewModel {
    // Deletes players from the roster and removes every related lineup/batting reference.
    func deletePlayers(at offsets: IndexSet) {
        // Capture IDs before removing players so related state can be cleaned up safely.
        let deletedIDs = offsets.map { players[$0].id }
        players.remove(atOffsets: offsets)

        // Remove deleted players from batting order and DH selections.
        battingOrderIDs.removeAll { deletedIDs.contains($0) }
        // Clear current pitcher/catcher if either deleted player was assigned there.
        if let designatedHitterID, deletedIDs.contains(designatedHitterID) { self.designatedHitterID = nil }
        if let designatedHitterForID, deletedIDs.contains(designatedHitterForID) { self.designatedHitterForID = nil }

        // Clear current pitcher/catcher if either deleted player was assigned there.
        if let pitcherID, deletedIDs.contains(pitcherID) { self.pitcherID = nil }
        if let catcherID, deletedIDs.contains(catcherID) { self.catcherID = nil }

        // Remove deleted players from the current field lineup.
        lineup = lineup.filter { !deletedIDs.contains($0.value) }
        // Remove deleted players from every saved inning lineup.
        for inning in inningLineups.keys {
            inningLineups[inning] = inningLineups[inning]?.filter { !deletedIDs.contains($0.value) } ?? [:]
        }
        // Remove deleted players from saved inning pitcher/catcher assignments.
        for inning in inningPitcherIDs.keys where deletedIDs.contains(inningPitcherIDs[inning]!) {
            inningPitcherIDs.removeValue(forKey: inning)
        }
        // Remove deleted players from saved inning pitcher/catcher assignments.
        for inning in inningCatcherIDs.keys where deletedIDs.contains(inningCatcherIDs[inning]!) {
            inningCatcherIDs.removeValue(forKey: inning)
        }
        save()
    }

    // Deletes one player by converting the ID into the IndexSet used by list deletion.
    func deletePlayer(playerID: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        deletePlayers(at: IndexSet(integer: index))
    }

    // Deletes all players and player-related lineup state while keeping coaches intact.
    func deleteAllPlayersOnly() {
        // Clear roster and every player-dependent assignment collection.
        players.removeAll()
        pitcherID = nil
        catcherID = nil
        lineup.removeAll()
        inningLineups.removeAll()
        inningPitcherIDs.removeAll()
        inningCatcherIDs.removeAll()
        battingOrderIDs.removeAll()
        designatedHitterID = nil
        designatedHitterForID = nil
        save()
    }

    // Deletes all player data and coach data for the current team.
    func deleteAllPlayerData() {
        // Full team reset clears both roster and coaches plus all lineup references.
        players = []
        coaches = []
        battingOrderIDs = []
        pitcherID = nil
        catcherID = nil
        lineup = [:]
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        designatedHitterID = nil
        designatedHitterForID = nil
        save()
    }
}
