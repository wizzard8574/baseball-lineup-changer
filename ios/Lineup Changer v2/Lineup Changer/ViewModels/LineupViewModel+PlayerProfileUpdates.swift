// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+PlayerProfileUpdates.swift
//
//
//
// Player profile update helpers.
import Foundation

// MARK: - Update Player Profile
extension LineupViewModel {
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
}
