// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+PlayerCreation.swift
//
//
//
// Player creation helpers.
import Foundation

// MARK: - Create Player
extension LineupViewModel {
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
}
