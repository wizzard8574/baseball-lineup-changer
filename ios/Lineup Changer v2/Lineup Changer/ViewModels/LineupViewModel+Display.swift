// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Display.swift
//
//
//
// Player filtering, lineup resolution, and display formatting helpers.
import Foundation

// MARK: - Display Helpers
extension LineupViewModel {
    // Players eligible for field and lineup use.
    var activePlayers: [Player] {
        players.filter { $0.status == .active }
    }

    // Current field assignments resolved to full Player values for UI and export surfaces.
    var resolvedLineup: [FieldPosition: Player] {
        resolvedLineup(from: lineup)
    }

    // Resolves a player-ID lineup into full Player values using the current roster.
    func resolvedLineup(from lineup: [FieldPosition: UUID]) -> [FieldPosition: Player] {
        let playersByID = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, $0) })
        return Dictionary(uniqueKeysWithValues: lineup.compactMap { position, playerID in
            guard let player = playersByID[playerID] else { return nil }
            return (position, player)
        })
    }

    // Builds a player label based on the current full-name display setting.
    func displayLabel(for player: Player) -> String {
        // Split the name so compact display can use first initial and last name.
        let nameParts = player.name.split(separator: " ").map(String.init)
        let lastName = nameParts.last ?? player.name
        let firstInitial = nameParts.first?.first.map { "\($0)." } ?? ""
        let initialLastName = firstInitial.isEmpty ? lastName : "\(firstInitial) \(lastName)"

        // Full display keeps the complete name and optional jersey number.
        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        }

        return player.number.isEmpty ? initialLastName : "#\(player.number) \(initialLastName)"
    }
}
