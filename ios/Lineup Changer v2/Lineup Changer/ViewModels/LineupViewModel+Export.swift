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
    // MARK: Full App State Export
    // Exports the full app state as encoded JSON data.
    // The export excludes coaches and GameChanger stats so backup/share files stay lighter
    // and avoid including stat data that may have come from an external source.
    func exportAppStateData() -> Data {
        // Start from the current saved state, then sanitize fields before encoding.
        var exportState = currentAppState()
        exportState.coaches = []
        exportState.players = exportState.players.map { playerWithoutGameChangerStats($0) }
        exportState.lineup = lineupWithoutGameChangerStats(exportState.lineup)
        exportState.inningLineups = inningLineupsWithoutGameChangerStats(exportState.inningLineups)
        exportState.teamSnapshots = exportState.teamSnapshots.map { teamSnapshotWithoutGameChangerStats($0) }
        exportState.sportTeamStates = exportState.sportTeamStates.mapValues { sportTeamStateWithoutGameChangerStats($0) }

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
