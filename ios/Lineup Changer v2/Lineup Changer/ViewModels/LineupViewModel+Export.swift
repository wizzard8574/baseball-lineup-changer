// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Export.swift
//
//
//
// Data export helpers for app-state, player, and coach sharing files.
import Foundation

// MARK: - Export Methods
extension LineupViewModel {
    // MARK: Selected Team App State Export
    // Exports only the selected sport and selected team as encoded JSON data.
    // The export excludes coaches and GameChanger stats so share files stay lighter
    // and avoid including stat data that may have come from an external source.
    func exportAppStateData() -> Data {
        // Start from the current saved state, then reduce it to the selected sport/team only.
        let currentState = currentAppState()
        let selectedSnapshot = teamSnapshotWithoutGameChangerStats(currentTeamSnapshot(for: selectedSport))
        let selectedTeamNames = [selectedTeamName]
        let selectedSportTeamState = SportTeamState(
            selectedTeamIndex: 0,
            teamNames: selectedTeamNames,
            teamSnapshots: [selectedSnapshot],
            hasCustomTeamNames: true
        )

        var exportState = currentState
        exportState.coaches = []
        exportState.players = selectedSnapshot.players
        exportState.lineup = selectedSnapshot.lineup
        exportState.lineupIDs = selectedSnapshot.lineupIDs
        exportState.selectedInning = selectedSnapshot.selectedInning
        exportState.inningLineups = selectedSnapshot.inningLineups
        exportState.inningLineupIDs = selectedSnapshot.inningLineupIDs
        exportState.inningPitcherIDs = selectedSnapshot.inningPitcherIDs
        exportState.inningCatcherIDs = selectedSnapshot.inningCatcherIDs
        exportState.battingOrderIDs = selectedSnapshot.battingOrderIDs
        exportState.baseballLineupBatterCount = selectedSnapshot.baseballLineupBatterCount
        exportState.designatedHitterID = selectedSnapshot.designatedHitterID
        exportState.designatedHitterForID = selectedSnapshot.designatedHitterForID
        exportState.basketballUsesExplicitStartingLineup = selectedSnapshot.basketballUsesExplicitStartingLineup
        exportState.basketballStartingLineupIDs = selectedSnapshot.basketballStartingLineupIDs
        exportState.basketballCourtLineupIDsByPeriod = selectedSnapshot.basketballCourtLineupIDsByPeriod
        exportState.preGameNotes = selectedSnapshot.preGameNotes
        exportState.postGameNotes = selectedSnapshot.postGameNotes
        exportState.coachNotes = selectedSnapshot.coachNotes
        exportState.selectedSport = selectedSport
        exportState.selectedTeamIndex = 0
        exportState.teamNames = selectedTeamNames
        exportState.teamSnapshots = [selectedSnapshot]
        exportState.sportTeamStates = [selectedSport: selectedSportTeamState]

        // Encode the sanitized state into JSON data for sharing or saving.
        do {
            return try JSONEncoder().encode(exportState)
        } catch {
            // Return empty data rather than crashing if encoding fails.
            print("Failed to export app state: \(error)")
            return Data()
        }
    }

    // MARK: Player Export
    // Exports a lightweight player list containing only name, jersey number, and cell number.
    func exportPlayerNameNumberData() -> Data {
        // Local DTO used only for this simple sharing format.
        struct SharedPlayer: Codable {
            let name: String
            let number: String
            let cell: String
        }

        // Convert the full Player models into the smaller shareable format.
        let sharedPlayers = players.map { player in
            SharedPlayer(name: player.name, number: player.number, cell: player.cell)
        }

        // Encode the shared player list as JSON.
        do {
            return try JSONEncoder().encode(sharedPlayers)
        } catch {
            print("Failed to export player name, number, and cell data: \(error)")
            return Data()
        }
    }

    // MARK: Coach Export
    // Exports coach contact data using a compact sharing format.
    func exportCoachData() -> Data {
        // Local DTO used only for coach export/import sharing.
        struct SharedCoach: Codable {
            let name: String
            let number: String
            let cell: String
            let role: String
        }

        // Convert Coach models into the compact export representation.
        let sharedCoaches = coaches.map { coach in
            SharedCoach(name: coach.name, number: coach.number, cell: coach.cell, role: coach.role)
        }

        do {
            return try JSONEncoder().encode(sharedCoaches)
        } catch {
            print("Failed to export coach data: \(error)")
            return Data()
        }
    }
}
