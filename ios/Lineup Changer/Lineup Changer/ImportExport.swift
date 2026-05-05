//
//  ImportExport.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import SwiftUI

import Foundation

extension LineupViewModel {

// MARK: - Export Helper Methods (Omit GameChanger Stats)

private func playerWithoutGameChangerStats(_ player: Player) -> Player {
    var copy = player
    copy.gameChangerStats = nil
    return copy
}

private func lineupWithoutGameChangerStats(_ lineup: [FieldPosition: Player]) -> [FieldPosition: Player] {
    Dictionary(uniqueKeysWithValues: lineup.map { position, player in
        (position, playerWithoutGameChangerStats(player))
    })
}

private func inningLineupsWithoutGameChangerStats(_ lineups: [Int: [FieldPosition: Player]]) -> [Int: [FieldPosition: Player]] {
    Dictionary(uniqueKeysWithValues: lineups.map { inning, lineup in
        (inning, lineupWithoutGameChangerStats(lineup))
    })
}

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

func exportAppStateData() -> Data {
    var exportState = currentAppState()
    exportState.coaches = []
    exportState.players = exportState.players.map { playerWithoutGameChangerStats($0) }
    exportState.lineup = lineupWithoutGameChangerStats(exportState.lineup)
    exportState.inningLineups = inningLineupsWithoutGameChangerStats(exportState.inningLineups)
    exportState.teamSnapshots = exportState.teamSnapshots.map { teamSnapshotWithoutGameChangerStats($0) }

    do {
        return try JSONEncoder().encode(exportState)
    } catch {
        print("Failed to export app state: \(error)")
        return Data()
    }
}

func exportPlayerNameNumberData() -> Data {
    struct SharedPlayer: Codable {
        let name: String
        let number: String
        let cell: String
    }

    let sharedPlayers = players.map { player in
        SharedPlayer(name: player.name, number: player.number, cell: player.cell)
    }

    do {
        return try JSONEncoder().encode(sharedPlayers)
    } catch {
        print("Failed to export player name, number, and cell data: \(error)")
        return Data()
    }
}

func exportCoachData() -> Data {
    struct SharedCoach: Codable {
        let name: String
        let number: String
        let cell: String
        let role: String
    }

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

func importCoachData(_ data: Data) throws {
    struct SharedCoach: Codable {
        let name: String
        let number: String?
        let cell: String?
        let role: String?
    }

    let sharedCoaches = try JSONDecoder().decode([SharedCoach].self, from: data)

    for sharedCoach in sharedCoaches {
        let trimmedName = sharedCoach.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = (sharedCoach.number ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCell = (sharedCoach.cell ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = (sharedCoach.role ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { continue }

        coaches.append(Coach(name: trimmedName, number: trimmedNumber, cell: trimmedCell, role: trimmedRole))
    }

    save()
}

func importAppStateData(_ data: Data) throws {
    let state = try JSONDecoder().decode(AppState.self, from: data)
    applyAppState(state)
    save()
}

func importPlayerNameNumberData(_ data: Data) throws {
    struct SharedPlayer: Codable {
        let name: String
        let number: String
        let cell: String?
    }

    let sharedPlayers = try JSONDecoder().decode([SharedPlayer].self, from: data)

    for sharedPlayer in sharedPlayers {
        let trimmedName = sharedPlayer.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = sharedPlayer.number.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCell = (sharedPlayer.cell ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { continue }

        players.append(Player(name: trimmedName, number: trimmedNumber, cell: trimmedCell))
    }

    syncBattingOrder()
    save()
}

func importGameChangerStatsData(_ data: Data) throws -> Int {
    guard let rawString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
        throw NSError(domain: "GameChangerImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not read GameChanger file."])
    }

    let rows = parseCSV(rawString)
    guard rows.count > 1 else {
        throw NSError(domain: "GameChangerImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "GameChanger file has no stat rows."])
    }

    guard let headerRowIndex = rows.firstIndex(where: { row in
        let normalizedRow = row.map { normalizeHeader($0) }
        return (normalizedRow.contains("first") && normalizedRow.contains("last")) || normalizedRow.contains("player") || normalizedRow.contains("name")
    }) else {
        throw NSError(domain: "GameChangerImport", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not find GameChanger player header row."])
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

    var importedStatsByName: [String: PlayerGameChangerStats] = [:]
    var importedStatsByNumber: [String: PlayerGameChangerStats] = [:]

    for row in statRows {
        let playerName: String
        if let playerIndex, row.indices.contains(playerIndex) {
            playerName = row[playerIndex]
        } else if let firstNameIndex, let lastNameIndex,
                  row.indices.contains(firstNameIndex), row.indices.contains(lastNameIndex) {
            playerName = "\(row[firstNameIndex]) \(row[lastNameIndex])"
        } else {
            continue
        }

        let normalizedName = normalizePlayerName(playerName)
        let normalizedNumber = value(from: row, at: numberIndex).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty || !normalizedNumber.isEmpty else { continue }

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

        if !normalizedName.isEmpty {
            importedStatsByName[normalizedName] = stats
        }

        if !normalizedNumber.isEmpty && normalizedNumber != "—" {
            importedStatsByNumber[normalizedNumber] = stats
        }
    }

    var matchCount = 0
    for index in players.indices {
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

func clearGameChangerStats() {
    for index in players.indices {
        players[index].gameChangerStats = nil
    }
    save()
}


private func value(from row: [String], at index: Int?) -> String {
    guard let index, row.indices.contains(index) else { return "—" }
    let trimmed = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "—" : trimmed
}

private func normalizeHeader(_ value: String) -> String {
    value
        .lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: "_", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func normalizePlayerName(_ value: String) -> String {
    value
        .lowercased()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func csvEscapedValue(_ value: String) -> String {
    let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return needsQuotes ? "\"\(escaped)\"" : escaped
}

private func parseCSV(_ text: String) -> [[String]] {
    var rows: [[String]] = []
    var row: [String] = []
    var field = ""
    var insideQuotes = false
    var iterator = Array(text).makeIterator()

    while let character = iterator.next() {
        if character == "\"" {
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
            row.append(field)
            field = ""
        } else if character == "\n", !insideQuotes {
            row.append(field)
            rows.append(row)
            row = []
            field = ""
        } else if character != "\r" {
            field.append(character)
        }
    }

    if !field.isEmpty || !row.isEmpty {
        row.append(field)
        rows.append(row)
    }

    return rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
}


}
