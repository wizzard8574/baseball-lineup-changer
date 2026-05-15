// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Import.swift
//
//
//
// Data import helpers for app-state, player, and coach sharing files.
import Foundation

// MARK: - Import Methods
extension LineupViewModel {
    // MARK: Coach Import
    // Imports coaches from the compact coach-sharing JSON format.
    // Invalid blank-name rows are ignored instead of creating empty coach records.
    func importCoachData(_ data: Data) throws {
        // Optional fields make the importer tolerant of older or partial coach files.
        struct SharedCoach: Codable {
            let name: String
            let number: String?
            let cell: String?
            let role: String?
        }

        // Decode the incoming JSON into the lightweight import format.
        let sharedCoaches = try JSONDecoder().decode([SharedCoach].self, from: data)

        for sharedCoach in sharedCoaches {
            // Clean up imported text so accidental whitespace does not become saved data.
            let trimmedName = sharedCoach.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNumber = (sharedCoach.number ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCell = (sharedCoach.cell ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedRole = (sharedCoach.role ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip rows that do not contain a usable coach name.
            guard !trimmedName.isEmpty else { continue }

            coaches.append(Coach(name: trimmedName, number: trimmedNumber, cell: trimmedCell, role: trimmedRole))
        }

        // Persist imported coaches after all valid rows have been appended.
        save()
    }

    // MARK: Full App State Import
    // Imports a full app-state backup and applies it to the current view model.
    func importAppStateData(_ data: Data) throws {
        // Decode first so invalid files fail before mutating current app state.
        let state = try JSONDecoder().decode(AppState.self, from: data)
        applyAppState(state)
        save()
    }

    // MARK: Player Import
    // Imports players from the lightweight player-sharing JSON format.
    // Imported players are appended to the current roster.
    func importPlayerNameNumberData(_ data: Data) throws {
        // Cell is optional so older exports without phone numbers can still be imported.
        struct SharedPlayer: Codable {
            let name: String
            let number: String
            let cell: String?
        }

        // Decode the incoming JSON into lightweight player rows.
        let sharedPlayers = try JSONDecoder().decode([SharedPlayer].self, from: data)

        for sharedPlayer in sharedPlayers {
            // Trim imported values before creating Player models.
            let trimmedName = sharedPlayer.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNumber = sharedPlayer.number.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCell = (sharedPlayer.cell ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            // Do not create players with blank names.
            guard !trimmedName.isEmpty else { continue }

            players.append(Player(name: trimmedName, number: trimmedNumber, cell: trimmedCell))
        }

        // Ensure the batting order includes newly imported players before saving.
        syncBattingOrder()
        save()
    }
}
