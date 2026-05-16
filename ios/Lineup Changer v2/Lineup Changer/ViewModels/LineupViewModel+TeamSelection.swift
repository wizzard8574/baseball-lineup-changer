// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+TeamSelection.swift
//
//
//
// Team-slot selection and naming helpers.
import Foundation

// MARK: - Team Selection
extension LineupViewModel {
    // Current team name, falling back to a generated name if the index is invalid.
    var selectedTeamName: String {
        guard teamNames.indices.contains(selectedTeamIndex) else { return "Team \(selectedTeamIndex + 1)" }
        return teamNames[selectedTeamIndex]
    }

    // Saves the current team snapshot, switches team slots, and restores that team's data.
    func selectTeam(_ index: Int) {
        // Only two team slots are supported, so clamp the requested index.
        let safeIndex = min(max(index, 0), 1)
        guard safeIndex != selectedTeamIndex else { return }

        // Preserve the outgoing team's state before switching.
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot(for: selectedSport)
        selectedTeamIndex = safeIndex

        let wasApplyingSavedState = isApplyingSavedState
        isApplyingSavedState = true

        // Restore an existing snapshot or start the destination team empty.
        if let snapshot = teamSnapshots[safeIndex] {
            applyTeamSnapshot(snapshot)
        } else {
            applyTeamSnapshot(emptyTeamSnapshot(for: selectedSport))
        }

        isApplyingSavedState = wasApplyingSavedState
        save()
    }

    // Renames the currently selected team after trimming blank space.
    func updateSelectedTeamName(_ newName: String) {
        // Ignore blank names so the team picker always has visible text.
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, teamNames.indices.contains(selectedTeamIndex) else { return }
        teamNames[selectedTeamIndex] = trimmed
        var selectedSportState = currentSportTeamState(for: selectedSport)
        selectedSportState.hasCustomTeamNames = true
        sportTeamStates[selectedSport] = selectedSportState
        save()
    }

    // Swaps Team 1 and Team 2 for the currently selected sport.
    func switchTeamSlots() {
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot(for: selectedSport)

        var updatedNames = normalizedTeamNames(teamNames, for: selectedSport)
        var updatedSnapshots = teamSnapshots.enumerated().map { _, snapshot in
            snapshot ?? emptyTeamSnapshot(for: selectedSport)
        }

        updatedNames.swapAt(0, 1)
        updatedSnapshots.swapAt(0, 1)

        teamNames = updatedNames
        teamSnapshots = updatedSnapshots.map(Optional.some)
        selectedTeamIndex = selectedTeamIndex == 0 ? 1 : 0

        let wasApplyingSavedState = isApplyingSavedState
        isApplyingSavedState = true
        applyTeamSnapshot(updatedSnapshots[selectedTeamIndex])
        isApplyingSavedState = wasApplyingSavedState

        var selectedSportState = currentSportTeamState(for: selectedSport)
        selectedSportState.hasCustomTeamNames = updatedNames != defaultTeamNames(for: selectedSport)
        sportTeamStates[selectedSport] = selectedSportState
        save()
    }

    // Deletes the selected team slot for the current sport by resetting its name and data.
    func deleteSelectedTeam() {
        let deletedIndex = selectedTeamIndex
        let defaults = defaultTeamNames(for: selectedSport)
        var updatedNames = normalizedTeamNames(teamNames, for: selectedSport)
        var updatedSnapshots = teamSnapshots.enumerated().map { _, snapshot in
            snapshot ?? emptyTeamSnapshot(for: selectedSport)
        }

        updatedNames[deletedIndex] = defaults[deletedIndex]
        updatedSnapshots[deletedIndex] = emptyTeamSnapshot(for: selectedSport)

        teamNames = updatedNames
        teamSnapshots = updatedSnapshots.map(Optional.some)

        let wasApplyingSavedState = isApplyingSavedState
        isApplyingSavedState = true
        applyTeamSnapshot(updatedSnapshots[deletedIndex])
        isApplyingSavedState = wasApplyingSavedState

        var selectedSportState = currentSportTeamState(for: selectedSport)
        selectedSportState.hasCustomTeamNames = updatedNames != defaults
        sportTeamStates[selectedSport] = selectedSportState
        save()
    }
}
