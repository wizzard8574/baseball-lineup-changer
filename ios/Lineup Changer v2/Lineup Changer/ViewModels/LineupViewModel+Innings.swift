// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Innings.swift
//
//
//
import Foundation

// MARK: - Inning Selection and Persistence
extension LineupViewModel {
// MARK: - Inning Selection and Persistence
// Saves the current inning, switches to another inning, and loads its saved lineup.
    func selectInning(_ inning: Int) {
        // Capture edits before leaving the current inning.
        saveCurrentInningState()
        // Clamp the requested inning into the valid range.
        selectedInning = min(max(inning, 1), numberOfInnings)

        // If this inning has never been edited, seed it from the previous inning.
        if inningLineups[selectedInning] == nil, selectedInning > 1 {
            inningLineups[selectedInning] = inningLineups[selectedInning - 1] ?? lineup
            inningPitcherIDs[selectedInning] = inningPitcherIDs[selectedInning - 1]
            inningCatcherIDs[selectedInning] = inningCatcherIDs[selectedInning - 1]
        }

        // Load the selected inning's lineup and battery assignments into active state.
        lineup = inningLineups[selectedInning] ?? [:]
        pitcherID = inningPitcherIDs[selectedInning]
        catcherID = inningCatcherIDs[selectedInning]
        syncBaseballFieldAssignmentsToLineupBattersIfNeeded()
        save()
    }

// Stores the current lineup, pitcher, and catcher values under the selected inning.
    func saveCurrentInningState() {
        // Save the visible defensive assignments for this inning.
        inningLineups[selectedInning] = lineup

        if let pitcherID {
            inningPitcherIDs[selectedInning] = pitcherID
        } else {
            inningPitcherIDs.removeValue(forKey: selectedInning)
        }

        if let catcherID {
            inningCatcherIDs[selectedInning] = catcherID
        } else {
            inningCatcherIDs.removeValue(forKey: selectedInning)
        }
    }

// MARK: - Pitcher / Catcher Updates
// Updates pitcher state and prevents the same player from also being catcher.
    func updatePitcher(_ playerID: UUID?) {
        // Store the new pitcher selection.
        pitcherID = playerID
        if catcherID == playerID { catcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

// Updates catcher state and prevents the same player from also being pitcher.
    func updateCatcher(_ playerID: UUID?) {
        // Store the new catcher selection.
        catcherID = playerID
        if pitcherID == playerID { pitcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

// MARK: - Forward Fill Helpers
// Copies the current inning forward only into later innings that are still empty.
    func copyCurrentInningForwardIfNeeded() {
        // There are no later innings to update from the final inning.
        guard selectedInning < numberOfInnings else { return }

        // Preserve already-edited future innings while seeding blank ones.
        for inning in (selectedInning + 1)...numberOfInnings {
            if inningLineups[inning] == nil || inningLineups[inning]?.isEmpty == true {
                inningLineups[inning] = lineup
                inningPitcherIDs[inning] = pitcherID
                inningCatcherIDs[inning] = catcherID
            }
        }
    }
}
