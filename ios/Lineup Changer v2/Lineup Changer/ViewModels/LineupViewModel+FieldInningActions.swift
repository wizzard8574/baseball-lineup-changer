// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+FieldInningActions.swift
//
//
//
// Field inning copy and clear actions.
import Foundation

// MARK: - Inning Copy / Clear Actions
extension LineupViewModel {
    // Copies the currently visible lineup and pitcher/catcher selections to every inning.
    func setCurrentLineupForAllInnings() {
        // Ensure the current inning is stored before duplicating it.
        saveCurrentInningState()

        // Replace every inning with the current field state.
        for inning in 1...numberOfInnings {
            inningLineups[inning] = lineup

            if let pitcherID {
                inningPitcherIDs[inning] = pitcherID
            } else {
                inningPitcherIDs.removeValue(forKey: inning)
            }

            if let catcherID {
                inningCatcherIDs[inning] = catcherID
            } else {
                inningCatcherIDs.removeValue(forKey: inning)
            }
        }

        save()
    }

    // Clears only the selected inning's lineup and battery assignments.
    func clearInning() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups[selectedInning] = [:]
        inningPitcherIDs.removeValue(forKey: selectedInning)
        inningCatcherIDs.removeValue(forKey: selectedInning)
        save()
    }

    // Clears all inning lineups and all saved pitcher/catcher assignments.
    func clearAllInnings() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        save()
    }
}
