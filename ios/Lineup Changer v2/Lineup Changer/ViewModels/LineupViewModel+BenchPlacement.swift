// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+BenchPlacement.swift
//
//
//
// Bench-to-field placement helpers.
import Foundation

// MARK: - Bench Placement
extension LineupViewModel {
    // Places a bench player into the field in the best open/rated position.
    @discardableResult
    func placeBenchPlayerInField(playerID: UUID) -> Bool {
        // Only active players can be placed in the field.
        guard let player = activePlayers.first(where: { $0.id == playerID }) else { return false }

        // Prefer the player's rated positions, sorted best rating first.
        let ratedPositions = FieldPosition.autoAssignedPositions
            .filter { player.positionRatings[$0] != nil }
            .sorted { lhs, rhs in
                let lhsRating = player.positionRatings[lhs] ?? 99
                let rhsRating = player.positionRatings[rhs] ?? 99

                if lhsRating == rhsRating {
                    return lhs.rawValue < rhs.rawValue
                }

                return lhsRating < rhsRating
            }
        guard !ratedPositions.isEmpty else { return false }

        // Remove the player from any existing field slot before finding a new one.
        lineup = lineup.filter { _, existingPlayerID in
            existingPlayerID != playerID
        }

        // Choose the best open rated position, then progressively fall back if needed.
        if let openRatedPosition = ratedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openRatedPosition] = player.id
        } else if let bestRatedPosition = ratedPositions.first {
            lineup[bestRatedPosition] = player.id
        }

        // Save this placement and copy it forward to later empty innings.
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
        return true
    }
}
