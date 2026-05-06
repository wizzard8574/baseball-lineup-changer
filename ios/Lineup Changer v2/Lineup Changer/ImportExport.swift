// Created by Rich Morris on 5/5/26.
// Lineup Changer
// ImportExport.swift
//
//
//
// ImportExport.swift contains the data import and export helpers for LineupViewModel.
// It supports full app-state backups, player/coach sharing files, and GameChanger
// stat imports while intentionally omitting GameChanger stats from general exports.
import SwiftUI
import Foundation

// MARK: - LineupViewModel Import / Export Extension
// Import/export functionality is implemented as a LineupViewModel extension so
// persistence and data transformation logic can stay separate from core view-model state.
extension LineupViewModel {

    // MARK: - Export Sanitizing Helpers
    
    // Returns a copy of a player with GameChanger stats removed.
    // This keeps shared app/player exports focused on lineup data instead of imported stats.
    private func playerWithoutGameChangerStats(_ player: Player) -> Player {
        // Work on a copy so the in-memory player keeps its stats.
        var copy = player
        copy.gameChangerStats = nil
        return copy
    }

    // Removes GameChanger stats from every player stored in a field-position lineup.
    private func lineupWithoutGameChangerStats(_ lineup: [FieldPosition: Player]) -> [FieldPosition: Player] {
        Dictionary(uniqueKeysWithValues: lineup.map { position, player in
            (position, playerWithoutGameChangerStats(player))
        })
    }

    // Removes GameChanger stats from every inning's stored lineup.
    private func inningLineupsWithoutGameChangerStats(_ lineups: [Int: [FieldPosition: Player]]) -> [Int: [FieldPosition: Player]] {
        Dictionary(uniqueKeysWithValues: lineups.map { inning, lineup in
            (inning, lineupWithoutGameChangerStats(lineup))
        })
    }

    // Builds a sanitized team snapshot for export.
    // Coaches are intentionally omitted and player stats are stripped from all lineup data.
    private func teamSnapshotWithoutGameChangerStats(_ snapshot: TeamSnapshot) -> TeamSnapshot {
        TeamSnapshot(
            players: snapshot.players.map { playerWithoutGameChangerStats($0) },
            coaches: [],
            pitcherID: snapshot.pitcherID,
            catcherID: snapshot.catcherID,
            lineup: lineupWithoutGameChangerStats(snapshot.lineup),
            selectedInning: snapshot.selectedInning,
            inningLineups: inningLineupsWithoutGameChangerStats(snapshot.inningLineups),
            inningPitcherIDs: snapshot.inningPitcherIDs,
            inningCatcherIDs: snapshot.inningCatcherIDs,
            battingOrderIDs: snapshot.battingOrderIDs,
            designatedHitterID: snapshot.designatedHitterID,
            designatedHitterForID: snapshot.designatedHitterForID,
            preGameNotes: snapshot.preGameNotes,
            postGameNotes: snapshot.postGameNotes
        )
    }

    // MARK: - Export Methods
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

    // MARK: - Import Methods
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

    // MARK: - GameChanger Import
    // Imports GameChanger CSV stats and matches them to existing players by name or jersey number.
    // Returns the number of players whose stats were updated.
    func importGameChangerStatsData(_ data: Data) throws -> Int {
        // GameChanger files are usually UTF-8, but UTF-16 is accepted as a fallback.
        guard let rawString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            throw NSError(domain: "GameChangerImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not read GameChanger file."])
        }

        // Parse the CSV into rows before locating columns and player data.
        let rows = parseCSV(rawString)
        guard rows.count > 1 else {
            throw NSError(domain: "GameChangerImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "GameChanger file has no stat rows."])
        }

        // Find the header row by looking for common player-name column labels.
        guard let headerRowIndex = rows.firstIndex(where: { row in
            let normalizedRow = row.map { normalizeHeader($0) }
            return (normalizedRow.contains("first") && normalizedRow.contains("last")) || normalizedRow.contains("player") || normalizedRow.contains("name")
        }) else {
            throw NSError(domain: "GameChangerImport", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not find GameChanger player header row."])
        }

        // Everything after the header is treated as a potential stat row.
        let header = rows[headerRowIndex]
        let statRows = rows.dropFirst(headerRowIndex + 1)
        let normalizedHeader = header.map { normalizeHeader($0) }

        // Finds a CSV column by testing several possible header names.
        func columnIndex(_ names: [String]) -> Int? {
            for name in names {
                if let index = normalizedHeader.firstIndex(of: normalizeHeader(name)) {
                    return index
                }
            }
            return nil
        }

        // Resolve all supported GameChanger/stat column variations.
        let numberIndex = columnIndex(["Number", "No", "#", "Jersey", "Jersey Number"])
        let playerIndex = columnIndex(["Player", "Name", "Player Name", "Athlete"])
        let firstNameIndex = columnIndex(["First", "First Name", "FirstName"])
        let lastNameIndex = columnIndex(["Last", "Last Name", "LastName"])
        let avgIndex = columnIndex(["AVG", "BA", "Batting Average", "Batting Avg"])
        let obpIndex = columnIndex(["OBP", "On Base Percentage", "On-Base Percentage"])
        let opsIndex = columnIndex(["OPS", "On Base Plus Slugging", "On-Base Plus Slugging"])
        let slgIndex = columnIndex(["SLG", "Slugging", "Slugging Percentage"])
        let hitsIndex = columnIndex(["H", "Hits"])
        let rbiIndex = columnIndex(["RBI", "RBIs", "Runs Batted In"])
        let runsIndex = columnIndex(["R", "Runs"])
        let walksIndex = columnIndex(["BB", "Walks", "Base on Balls"])
        let strikeoutsIndex = columnIndex(["SO", "K", "Strikeouts", "Strike Outs"])

        // Build lookup dictionaries so existing players can be matched efficiently.
        var importedStatsByName: [String: PlayerGameChangerStats] = [:]
        var importedStatsByNumber: [String: PlayerGameChangerStats] = [:]

        for row in statRows {
            // Determine the player's name from either a combined name column or first/last columns.
            let playerName: String
            if let playerIndex, row.indices.contains(playerIndex) {
                playerName = row[playerIndex]
            } else if let firstNameIndex, let lastNameIndex,
                      row.indices.contains(firstNameIndex), row.indices.contains(lastNameIndex) {
                playerName = "\(row[firstNameIndex]) \(row[lastNameIndex])"
            } else {
                continue
            }

            // Normalize name and number so minor formatting differences do not block matching.
            let normalizedName = normalizePlayerName(playerName)
            let normalizedNumber = value(from: row, at: numberIndex).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedName.isEmpty || !normalizedNumber.isEmpty else { continue }

            // Extract the supported stat fields, using em dashes for missing values.
            let stats = PlayerGameChangerStats(
                avg: value(from: row, at: avgIndex),
                obp: value(from: row, at: obpIndex),
                ops: value(from: row, at: opsIndex),
                slg: value(from: row, at: slgIndex),
                hits: value(from: row, at: hitsIndex),
                rbi: value(from: row, at: rbiIndex),
                runs: value(from: row, at: runsIndex),
                walks: value(from: row, at: walksIndex),
                strikeouts: value(from: row, at: strikeoutsIndex)
            )

            // Store stats by normalized name when available.
            if !normalizedName.isEmpty {
                importedStatsByName[normalizedName] = stats
            }

            // Also store stats by jersey number so name mismatches can still import.
            if !normalizedNumber.isEmpty && normalizedNumber != "—" {
                importedStatsByNumber[normalizedNumber] = stats
            }
        }

        // Apply imported stats to current roster players and count successful matches.
        var matchCount = 0
        for index in players.indices {
            // Prefer name match, then fall back to jersey-number match.
            let normalizedName = normalizePlayerName(players[index].name)
            let normalizedNumber = players[index].number.trimmingCharacters(in: .whitespacesAndNewlines)

            if let stats = importedStatsByName[normalizedName] ?? importedStatsByNumber[normalizedNumber] {
                players[index].gameChangerStats = stats
                matchCount += 1
            }
        }

        save()
        return matchCount
    }

    // MARK: GameChanger Stats Cleanup
    // Removes all imported GameChanger stats from the current roster.
    func clearGameChangerStats() {
        // Iterate by index so each Player value can be updated in place.
        for index in players.indices {
            players[index].gameChangerStats = nil
        }
        save()
    }


    // MARK: - CSV Parsing Helpers
    // Safely reads a CSV field and returns an em dash when the value is missing or empty.
    private func value(from row: [String], at index: Int?) -> String {
        guard let index, row.indices.contains(index) else { return "—" }
        let trimmed = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }

    // MARK: CSV Normalization
    // Normalizes CSV headers by removing spacing and punctuation differences.
    private func normalizeHeader(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Normalizes player names for matching by lowercasing and keeping only alphanumeric tokens.
    private func normalizePlayerName(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: CSV Escaping
    // Escapes a string for CSV output by quoting values with commas, quotes, or line breaks.
    private func csvEscapedValue(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    // MARK: CSV Parser
    // Lightweight CSV parser that supports quoted fields, escaped quotes, commas, and newlines.
    private func parseCSV(_ text: String) -> [[String]] {
        // Accumulate parsed rows, the current row, and the current field being read.
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var iterator = Array(text).makeIterator()

        while let character = iterator.next() {
            // Quoted sections can contain commas and newlines without ending the field.
            if character == "\"" {
                // A doubled quote inside quoted text represents a literal quote character.
                if insideQuotes, let nextCharacter = iterator.next() {
                    if nextCharacter == "\"" {
                        field.append("\"")
                    } else {
                        insideQuotes = false
                        if nextCharacter == "," {
                            row.append(field)
                            field = ""
                        } else if nextCharacter == "\n" {
                            row.append(field)
                            rows.append(row)
                            row = []
                            field = ""
                        } else if nextCharacter != "\r" {
                            field.append(nextCharacter)
                        }
                    }
                } else {
                    insideQuotes.toggle()
                }
            } else if character == ",", !insideQuotes {
                // A comma outside quotes ends the current field.
                row.append(field)
                field = ""
            } else if character == "\n", !insideQuotes {
                // A newline outside quotes ends the current row.
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if character != "\r" {
                field.append(character)
            }
        }

        // Add the final field/row when the file does not end with a newline.
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        // Drop fully blank rows so import logic only sees meaningful records.
        return rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
    }


}
