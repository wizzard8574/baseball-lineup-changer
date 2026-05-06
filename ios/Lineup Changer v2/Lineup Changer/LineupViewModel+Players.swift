// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Players.swift
//
//
//
// Player-related LineupViewModel functionality.
// This extension manages player creation, deletion, profile updates, status changes,
// batting order synchronization, and cleanup of lineup references when players change.
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Player Management
extension LineupViewModel {
    
    // MARK: - Create Player
    // Adds a new player after trimming whitespace and validating the name.
    @discardableResult
    func addPlayer(name: String) -> Player? {
        // Ignore blank or whitespace-only player names.
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // New players are immediately added to the roster and batting order.
        let player = Player(name: trimmed)
        players.append(player)
        battingOrderIDs.append(player.id)
        save()
        return player
    }


    // MARK: - Delete Players
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
        lineup = lineup.filter { !deletedIDs.contains($0.value.id) }
        // Remove deleted players from every saved inning lineup.
        for inning in inningLineups.keys {
            inningLineups[inning] = inningLineups[inning]?.filter { !deletedIDs.contains($0.value.id) } ?? [:]
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

    // MARK: - Update Player Profile
    // Updates a player's saved name after trimming whitespace.
    func renamePlayer(playerID: UUID, newName: String) {
        // Prevent saving empty player names.
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        // Update the matching player record in place.
        players[index].name = trimmed
        save()
    }

    // Updates the player's jersey number.
    func updatePlayerNumber(playerID: UUID, newNumber: String) {
        // Store a cleaned version of the entered number.
        let trimmed = newNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].number = trimmed
        save()
    }
    
    // Updates the player's cell phone number.
    func updatePlayerCell(playerID: UUID, newCell: String) {

        // Remove accidental leading/trailing spaces from typed or imported values.
        let trimmedCell = newCell.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].cell = trimmedCell

        save()

    }

    // Updates the player's speed/steal rating.
    func updatePlayerSpeed(playerID: UUID, speedRating: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].speedRating = speedRating
        save()
    }
    
    // Updates freeform notes stored on the player profile.
    func updatePlayerNotes(playerID: UUID, notes: String) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].notes = notes
        save()
    }


    // MARK: - Player Status Updates
    // Updates active/guest/injured/unavailable status and cleans up assignments when needed.
    func setPlayerStatus(playerID: UUID, status: PlayerStatus) {
        // Ignore status changes for players no longer in the roster.
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        // Replace the value-type Player so any copied lineup entries can be refreshed later.
        var refreshedPlayer = players[index]
        refreshedPlayer.status = status
        players[index] = refreshedPlayer

        // Injured and unavailable players should not remain in field or DH assignments.
        if status == .injured || status == .unavailable {
            // Clear current role assignments for the removed player.
            if pitcherID == playerID { pitcherID = nil }
            if catcherID == playerID { catcherID = nil }
            if designatedHitterID == playerID { designatedHitterID = nil }
            if designatedHitterForID == playerID { designatedHitterForID = nil }

            // Remove the player from the current field lineup.
            lineup = lineup.filter { _, player in
                player.id != playerID
            }

            // Remove the player from every saved inning lineup.
            for inning in Array(inningLineups.keys) {
                inningLineups[inning] = inningLineups[inning]?.filter { _, player in
                    player.id != playerID
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
        } else {
            // If the player remains eligible, refresh copied Player values in current lineup slots.
            for position in Array(lineup.keys) where lineup[position]?.id == playerID {
                lineup[position] = refreshedPlayer
            }

            // Refresh copied Player values in saved inning lineups as well.
            for inning in Array(inningLineups.keys) {
                guard let positions = inningLineups[inning]?.keys else { continue }

                for position in Array(positions) where inningLineups[inning]?[position]?.id == playerID {
                    inningLineups[inning]?[position] = refreshedPlayer
                }
            }
        }

        // Keep batting order and saved inning state aligned with the updated roster.
        syncBattingOrder()
        saveCurrentInningState()
        save()
    }
    // MARK: - Bulk Delete
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
    // MARK: - Batting Order Helpers
    // Ensures battingOrderIDs matches the current roster without losing existing order.
    func syncBattingOrder() {
        // Remove IDs for players that no longer exist.
        let existingIDs = Set(players.map { $0.id })
        battingOrderIDs.removeAll { !existingIDs.contains($0) }

        // Append any new players that are missing from the batting order.
        for player in players where !battingOrderIDs.contains(player.id) {
            battingOrderIDs.append(player.id)
        }
        save()
    }
    // Finds a player by ID.
    func player(for id: UUID) -> Player? {
        players.first { $0.id == id }
    }
    // Reorders batting order IDs after the user drags rows in the lineup screen.
    func moveBatters(from source: IndexSet, to destination: Int) {
        // Sync first so the move operation acts on a valid, current batting order.
        syncBattingOrder()
        battingOrderIDs.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
