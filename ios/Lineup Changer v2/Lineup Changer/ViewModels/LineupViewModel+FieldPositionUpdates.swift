// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+FieldPositionUpdates.swift
//
//
//
// Manual field assignment updates.
import Foundation

// MARK: - Manual Field Position Updates
extension LineupViewModel {
    // Updates one defensive position and keeps inning state synchronized.
    func updateFieldPosition(_ position: FieldPosition, playerID: UUID?) {
        if let playerID, !isBaseballFieldAssignablePlayer(playerID) {
            return
        }

        // Pitcher updates also update the dedicated pitcherID state.
        if position == .pitcher {
            updatePitcher(playerID)
            // Mirror pitcher assignment into the lineup dictionary for field display.
            if let playerID, isBaseballFieldAssignablePlayer(playerID) {
                lineup[.pitcher] = playerID
            } else {
                lineup.removeValue(forKey: .pitcher)
            }
            saveCurrentInningState()
            copyCurrentInningForwardIfNeeded()
            save()
            return
        }

        // Catcher updates also update the dedicated catcherID state.
        if position == .catcher {
            updateCatcher(playerID)
            // Mirror catcher assignment into the lineup dictionary for field display.
            if let playerID, isBaseballFieldAssignablePlayer(playerID) {
                lineup[.catcher] = playerID
            } else {
                lineup.removeValue(forKey: .catcher)
            }
            saveCurrentInningState()
            copyCurrentInningForwardIfNeeded()
            save()
            return
        }

        // Standard field positions store only in the lineup dictionary.
        if let playerID {
            // Ignore assignments for players who are no longer active.
            guard isBaseballFieldAssignablePlayer(playerID) else { return }

            // Remove this player from any other position before assigning the new one.
            lineup = lineup.filter { existingPosition, existingPlayerID in
                existingPosition == position || existingPlayerID != playerID
            }
            lineup[position] = playerID
        } else {
            lineup.removeValue(forKey: position)
        }

        // Persist and forward-fill this manual change when later innings are still empty.
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
}
