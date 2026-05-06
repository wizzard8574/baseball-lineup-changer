// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Persistence.swift
//
//
//
// Persistence-related LineupViewModel functionality.
// This extension saves and restores full app state, manages team snapshots,
// supports older saved-state formats, and keeps inning-specific data synchronized.
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - App State Persistence
extension LineupViewModel {
    
    // MARK: - Save / Load
    // Encodes the current app state and stores it in UserDefaults.
    func save() {
        // Avoid recursive saves while a saved state is actively being restored.
        guard !isApplyingSavedState else { return }

        do {
            // Build a complete AppState snapshot before encoding it.
            let data = try JSONEncoder().encode(currentAppState())
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            // Log save failures instead of interrupting the user's workflow.
            print("Failed to save app state: \(error)")
        }
    }

    // Loads saved app state from UserDefaults and applies it to the view model.
    func load() {
        // If no saved data exists, the app starts from default in-memory values.
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }

        do {
            // Suppress automatic saves while restoring published properties.
            isApplyingSavedState = true
            defer { isApplyingSavedState = false }

            // Decode the saved JSON into the app's persisted state model.
            let state = try JSONDecoder().decode(AppState.self, from: data)
            applyAppState(state)
        } catch {
            // Reset the guard flag manually because decoding failed before normal completion.
            isApplyingSavedState = false
            print("Failed to load app state: \(error)")
            // Preserve the unreadable payload for possible manual recovery/debugging.
            UserDefaults.standard.set(data, forKey: "LineupChangerRecoveryBackup")
        }
    }
 
    // MARK: - App State Snapshots
    // Builds a complete AppState value from the current view-model state.
    func currentAppState() -> AppState {
        // Refresh the selected team's snapshot before collecting all team data.
        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot()
        // Replace missing team snapshots with empty snapshots so the saved array is complete.
        let savedSnapshots = teamSnapshots.enumerated().map { index, snapshot in
            snapshot ?? emptyTeamSnapshot()
        }

        // Assemble global settings plus current/team-specific state into one persisted object.
        return AppState(
            players: players,
            coaches: coaches,
            pitcherID: pitcherID,
            catcherID: catcherID,
            lineup: lineup,
            selectedInning: selectedInning,
            inningLineups: inningLineups,
            inningPitcherIDs: inningPitcherIDs,
            inningCatcherIDs: inningCatcherIDs,
            showRatingsOnField: showRatingsOnField,
            showAssignedLineupTable: showAssignedLineupTable,
            showFullNameAndNumber: showFullNameAndNumber,
            showBenchOnField: showBenchOnField,
            showOnlyNineBattersAndDH: showOnlyNineBattersAndDH,
            showSlowSpeedBattingWarnings: showSlowSpeedBattingWarnings,
            fallBallEnabled: fallBallEnabled,
            fallBallYouthEnabled: fallBallYouthEnabled,
            battingOrderIDs: battingOrderIDs,
            designatedHitterID: designatedHitterID,
            designatedHitterForID: designatedHitterForID,
            preGameNotes: preGameNotes,
            postGameNotes: postGameNotes,
            coachNotes: coachNotes,
            selectedSport: selectedSport,
            selectedTeamIndex: selectedTeamIndex,
            teamNames: teamNames,
            teamSnapshots: savedSnapshots
        )
    }

    // Applies a decoded AppState to the view model.
    // Supports both current multi-team saves and older legacy saves without team snapshots.
    func applyAppState(_ state: AppState) {
        // Restore saved team names when present.
        if let savedNames = state.teamNames, savedNames.count >= 2 {
            teamNames = Array(savedNames.prefix(2))
        }

        // Clamp selected team to the two supported team slots.
        selectedTeamIndex = min(max(state.selectedTeamIndex ?? 0, 0), 1)

        // Prefer modern team snapshots when the saved state contains them.
        let savedSnapshots = state.teamSnapshots
        if savedSnapshots.count >= 2 {
            teamSnapshots = [savedSnapshots[0], savedSnapshots[1]]
            applyTeamSnapshot(savedSnapshots[selectedTeamIndex])
        } else {
            // Older saves stored team data directly on AppState, so wrap that data in a snapshot.
            let legacySnapshot = TeamSnapshot(
                players: state.players,
                coaches: state.coaches,
                pitcherID: state.pitcherID,
                catcherID: state.catcherID,
                lineup: state.lineup,
                selectedInning: state.selectedInning,
                inningLineups: state.inningLineups,
                inningPitcherIDs: state.inningPitcherIDs,
                inningCatcherIDs: state.inningCatcherIDs,
                battingOrderIDs: state.battingOrderIDs,
                designatedHitterID: state.designatedHitterID,
                designatedHitterForID: state.designatedHitterForID,
                preGameNotes: state.preGameNotes,
                postGameNotes: state.postGameNotes,
                coachNotes: state.coachNotes,
                selectedSport: state.selectedSport
            )
            teamSnapshots = [legacySnapshot, emptyTeamSnapshot()]
            applyTeamSnapshot(legacySnapshot)
        }

        // Restore global display and gameplay settings after team data is applied.
        showRatingsOnField = state.showRatingsOnField
        showAssignedLineupTable = state.showAssignedLineupTable
        showFullNameAndNumber = state.showFullNameAndNumber
        showBenchOnField = state.showBenchOnField
        showOnlyNineBattersAndDH = state.showOnlyNineBattersAndDH
        showSlowSpeedBattingWarnings = state.showSlowSpeedBattingWarnings
        fallBallEnabled = state.fallBallEnabled ?? false
        fallBallYouthEnabled = fallBallEnabled ? (state.fallBallYouthEnabled ?? false) : false
        selectedSport = state.selectedSport ?? .baseballSoftball
    }
   
    // MARK: - Team Snapshots
    // Creates a blank team snapshot used for empty team slots and migration defaults.
    func emptyTeamSnapshot() -> TeamSnapshot {
        // All team-specific collections start empty and settings fall back to baseball/softball.
        TeamSnapshot(
            players: [],
            coaches: [],
            pitcherID: nil,
            catcherID: nil,
            lineup: [:],
            selectedInning: 1,
            inningLineups: [:],
            inningPitcherIDs: [:],
            inningCatcherIDs: [:],
            battingOrderIDs: [],
            designatedHitterID: nil,
            designatedHitterForID: nil,
            preGameNotes: "",
            postGameNotes: "",
            coachNotes: "",
            selectedSport: .baseballSoftball
        )
    }

    // Captures the currently selected team's roster, lineup, notes, and inning data.
    func currentTeamSnapshot() -> TeamSnapshot {
        // Make sure any visible inning edits are included in the snapshot.
        saveCurrentInningState()
        // Store only team-specific state here; global display settings stay in AppState.
        return TeamSnapshot(
            players: players,
            coaches: coaches,
            pitcherID: pitcherID,
            catcherID: catcherID,
            lineup: lineup,
            selectedInning: selectedInning,
            inningLineups: inningLineups,
            inningPitcherIDs: inningPitcherIDs,
            inningCatcherIDs: inningCatcherIDs,
            battingOrderIDs: battingOrderIDs,
            designatedHitterID: designatedHitterID,
            designatedHitterForID: designatedHitterForID,
            preGameNotes: preGameNotes,
            postGameNotes: postGameNotes,
            coachNotes: coachNotes,
            selectedSport: selectedSport
        )
    }

    // Applies one team's saved snapshot into the active view-model properties.
    func applyTeamSnapshot(_ snapshot: TeamSnapshot) {
        // Restore roster, coaches, defensive assignments, batting order, notes, and sport state.
        players = snapshot.players
        coaches = snapshot.coaches ?? []
        pitcherID = snapshot.pitcherID
        catcherID = snapshot.catcherID
        lineup = snapshot.lineup
        // Keep restored inning selection inside the currently configured inning range.
        selectedInning = min(max(snapshot.selectedInning, 1), numberOfInnings)
        inningLineups = snapshot.inningLineups
        inningPitcherIDs = snapshot.inningPitcherIDs
        inningCatcherIDs = snapshot.inningCatcherIDs
        battingOrderIDs = snapshot.battingOrderIDs
        designatedHitterID = snapshot.designatedHitterID
        designatedHitterForID = snapshot.designatedHitterForID
        preGameNotes = snapshot.preGameNotes ?? ""
        postGameNotes = snapshot.postGameNotes ?? ""
        coachNotes = snapshot.coachNotes ?? ""
        selectedSport = snapshot.selectedSport ?? .baseballSoftball

        // Ensure the active lineup matches the selected inning's saved lineup.
        if inningLineups[selectedInning] == nil {
            inningLineups[selectedInning] = lineup
        } else {
            lineup = inningLineups[selectedInning] ?? [:]
        }

        // Restore pitcher/catcher from inning-specific values when they exist.
        pitcherID = inningPitcherIDs[selectedInning] ?? snapshot.pitcherID
        catcherID = inningCatcherIDs[selectedInning] ?? snapshot.catcherID
        // Reconcile batting order IDs with the restored player list.
        syncBattingOrder()
    }

    
    
}
