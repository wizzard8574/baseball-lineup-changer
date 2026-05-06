// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Ratings.swift
//
//
//
// Player rating-related LineupViewModel functionality.
// This extension manages defensive position ratings used by lineup generation,
// field assignment suggestions, and on-field rating displays.
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Player Position Ratings
extension LineupViewModel {
    
    // MARK: - Rating Updates
    // Assigns or updates a player's rating for a defensive position.
    func setRating(playerID: UUID, position: FieldPosition, rating: Int) {
        // Ignore updates for players that are no longer in the roster.
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        // Store the numeric rating for the selected defensive position.
        players[index].positionRatings[position] = rating
        // Persist the updated rating immediately.
        save()
    }

    // MARK: - Rating Removal
    // Removes a defensive position rating from a player.
    func removePosition(playerID: UUID, position: FieldPosition) {
        // Ignore removals for players that are no longer in the roster.
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        // Remove the stored rating entry for this position.
        players[index].positionRatings.removeValue(forKey: position)
        // Persist the updated rating set immediately.
        save()
    }
    
}
