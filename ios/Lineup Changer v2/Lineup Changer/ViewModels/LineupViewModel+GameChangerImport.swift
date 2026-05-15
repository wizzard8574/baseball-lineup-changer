// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+GameChangerImport.swift
//
//
//
import Foundation

// MARK: - GameChanger Import
extension LineupViewModel {
    // MARK: - GameChanger Import
    // Imports GameChanger CSV stats and matches them to existing players by name or jersey number.
    // Returns the number of players whose stats were updated.
    func importGameChangerStatsData(_ data: Data) throws -> Int {
        if selectedSport == .basketball {
            return try importBasketballGameChangerStatsData(data)
        }

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

    // MARK: Basketball GameChanger Import
    // Imports basketball GameChanger CSV stats and matches rows by first-name/last-initial style keys.
    private func importBasketballGameChangerStatsData(_ data: Data) throws -> Int {
        guard let rawString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            throw NSError(domain: "GameChangerImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not read GameChanger file."])
        }

        let rows = parseCSV(rawString)
        guard rows.count > 1 else {
            throw NSError(domain: "GameChangerImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "GameChanger file has no stat rows."])
        }

        guard let headerRowIndex = rows.firstIndex(where: { row in
            let normalizedRow = row.map { normalizeHeader($0) }
            return normalizedRow.contains("first") && normalizedRow.contains("last") && normalizedRow.contains("ppg")
        }) else {
            throw NSError(domain: "GameChangerImport", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not find GameChanger basketball stat header row."])
        }

        let header = rows[headerRowIndex]
        let statRows = rows.dropFirst(headerRowIndex + 1)
        let normalizedHeader = header.map { normalizeHeader($0) }

        func columnIndex(_ names: [String]) -> Int? {
            for name in names {
                if let index = normalizedHeader.firstIndex(of: normalizeHeader(name)) {
                    return index
                }
            }
            return nil
        }

        let numberIndex = columnIndex(["Number", "No", "#", "Jersey", "Jersey Number"])
        let firstNameIndex = columnIndex(["First", "First Name", "FirstName"])
        let lastNameIndex = columnIndex(["Last", "Last Name", "LastName"])
        let ppgIndex = columnIndex(["PPG", "Points Per Game"])
        let topgIndex = columnIndex(["TOPG", "Turnovers Per Game"])
        let rpgIndex = columnIndex(["RPG", "Rebounds Per Game"])
        let apgIndex = columnIndex(["APG", "Assists Per Game"])
        let spgIndex = columnIndex(["SPG", "Steals Per Game"])
        let bpgIndex = columnIndex(["BPG", "Blocks Per Game"])
        let tsPercentageIndex = columnIndex(["TS%", "TS", "True Shooting Percentage"])
        let astToIndex = columnIndex(["AST/TO", "ASTTO", "Assist Turnover Ratio", "Assist To Turnover Ratio"])

        var importedStatsByName: [String: PlayerBasketballGameChangerStats] = [:]
        var importedStatsByNumber: [String: PlayerBasketballGameChangerStats] = [:]

        for row in statRows {
            guard let firstNameIndex, let lastNameIndex,
                  row.indices.contains(firstNameIndex), row.indices.contains(lastNameIndex) else {
                continue
            }

            let firstName = row[firstNameIndex]
            let lastName = row[lastNameIndex]
            let normalizedNumber = value(from: row, at: numberIndex).trimmingCharacters(in: .whitespacesAndNewlines)

            let stats = PlayerBasketballGameChangerStats(
                ppg: value(from: row, at: ppgIndex),
                topg: value(from: row, at: topgIndex),
                rpg: value(from: row, at: rpgIndex),
                apg: value(from: row, at: apgIndex),
                spg: value(from: row, at: spgIndex),
                bpg: value(from: row, at: bpgIndex),
                trueShootingPercentage: value(from: row, at: tsPercentageIndex),
                assistTurnoverRatio: value(from: row, at: astToIndex)
            )

            for key in basketballGameChangerNameKeys(firstName: firstName, lastName: lastName) where !key.isEmpty {
                importedStatsByName[key] = stats
            }

            if !normalizedNumber.isEmpty && normalizedNumber != "—" {
                importedStatsByNumber[normalizedNumber] = stats
            }
        }

        var matchCount = 0
        for index in players.indices {
            let rosterKeys = basketballGameChangerNameKeys(for: players[index])
            let normalizedNumber = players[index].number.trimmingCharacters(in: .whitespacesAndNewlines)
            let stats = rosterKeys.lazy.compactMap { importedStatsByName[$0] }.first ?? importedStatsByNumber[normalizedNumber]

            if let stats {
                players[index].basketballGameChangerStats = stats
                matchCount += 1
            }
        }

        save()
        return matchCount
    }

    // MARK: GameChanger Stats Cleanup
    // Removes imported GameChanger stats for the currently selected sport and team only.
    func clearGameChangerStats() {
        // Iterate by index so each Player value can be updated in place.
        for index in players.indices {
            switch selectedSport {
            case .basketball:
                players[index].basketballGameChangerStats = nil
            default:
                players[index].gameChangerStats = nil
            }
        }

        teamSnapshots[selectedTeamIndex] = currentTeamSnapshot(for: selectedSport)
        sportTeamStates[selectedSport] = currentSportTeamState(for: selectedSport)
        save()
    }

    private func basketballGameChangerNameKeys(for player: Player) -> [String] {
        let parts = player.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard let firstName = parts.first else { return [] }

        if parts.count >= 2, let lastName = parts.last {
            return basketballGameChangerNameKeys(firstName: firstName, lastName: lastName)
        }

        return [normalizePlayerName(firstName)]
    }

    private func basketballGameChangerNameKeys(firstName: String, lastName: String) -> [String] {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstInitial = first.first.map(String.init) ?? ""
        let lastInitial = last.first.map(String.init) ?? ""

        return [
            normalizePlayerName("\(first) \(last)"),
            normalizePlayerName("\(first) \(lastInitial)"),
            normalizePlayerName("\(firstInitial) \(last)"),
            normalizePlayerName("\(firstInitial) \(lastInitial)")
        ]
        .filter { !$0.isEmpty }
    }
}
