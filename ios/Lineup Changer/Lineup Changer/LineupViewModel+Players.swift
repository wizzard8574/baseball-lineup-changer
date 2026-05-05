//
//  LineupViewModel+Players.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/3/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension LineupViewModel {
    
    @discardableResult
    func addPlayer(name: String) -> Player? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let player = Player(name: trimmed)
        players.append(player)
        battingOrderIDs.append(player.id)
        save()
        return player
    }


    func deletePlayers(at offsets: IndexSet) {
        let deletedIDs = offsets.map { players[$0].id }
        players.remove(atOffsets: offsets)

        battingOrderIDs.removeAll { deletedIDs.contains($0) }
        if let designatedHitterID, deletedIDs.contains(designatedHitterID) { self.designatedHitterID = nil }
        if let designatedHitterForID, deletedIDs.contains(designatedHitterForID) { self.designatedHitterForID = nil }

        if let pitcherID, deletedIDs.contains(pitcherID) { self.pitcherID = nil }
        if let catcherID, deletedIDs.contains(catcherID) { self.catcherID = nil }

        lineup = lineup.filter { !deletedIDs.contains($0.value.id) }
        for inning in inningLineups.keys {
            inningLineups[inning] = inningLineups[inning]?.filter { !deletedIDs.contains($0.value.id) } ?? [:]
        }
        for inning in inningPitcherIDs.keys where deletedIDs.contains(inningPitcherIDs[inning]!) {
            inningPitcherIDs.removeValue(forKey: inning)
        }
        for inning in inningCatcherIDs.keys where deletedIDs.contains(inningCatcherIDs[inning]!) {
            inningCatcherIDs.removeValue(forKey: inning)
        }
        save()
    }

    func deletePlayer(playerID: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        deletePlayers(at: IndexSet(integer: index))
    }

    func renamePlayer(playerID: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].name = trimmed
        save()
    }

    func updatePlayerNumber(playerID: UUID, newNumber: String) {
        let trimmed = newNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].number = trimmed
        save()
    }
    
    func updatePlayerCell(playerID: UUID, newCell: String) {

        let trimmedCell = newCell.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        players[index].cell = trimmedCell

        save()

    }

    func updatePlayerSpeed(playerID: UUID, speedRating: Int) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].speedRating = speedRating
        save()
    }
    
    func updatePlayerNotes(playerID: UUID, notes: String) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].notes = notes
        save()
    }


    func setPlayerStatus(playerID: UUID, status: PlayerStatus) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }

        var refreshedPlayer = players[index]
        refreshedPlayer.status = status
        players[index] = refreshedPlayer

        if status == .injured || status == .unavailable {
            if pitcherID == playerID { pitcherID = nil }
            if catcherID == playerID { catcherID = nil }
            if designatedHitterID == playerID { designatedHitterID = nil }
            if designatedHitterForID == playerID { designatedHitterForID = nil }

            lineup = lineup.filter { _, player in
                player.id != playerID
            }

            for inning in Array(inningLineups.keys) {
                inningLineups[inning] = inningLineups[inning]?.filter { _, player in
                    player.id != playerID
                } ?? [:]
            }

            for inning in Array(inningPitcherIDs.keys) where inningPitcherIDs[inning] == playerID {
                inningPitcherIDs.removeValue(forKey: inning)
            }

            for inning in Array(inningCatcherIDs.keys) where inningCatcherIDs[inning] == playerID {
                inningCatcherIDs.removeValue(forKey: inning)
            }
        } else {
            for position in Array(lineup.keys) where lineup[position]?.id == playerID {
                lineup[position] = refreshedPlayer
            }

            for inning in Array(inningLineups.keys) {
                guard let positions = inningLineups[inning]?.keys else { continue }

                for position in Array(positions) where inningLineups[inning]?[position]?.id == playerID {
                    inningLineups[inning]?[position] = refreshedPlayer
                }
            }
        }

        syncBattingOrder()
        saveCurrentInningState()
        save()
    }
    func deleteAllPlayersOnly() {
        players.removeAll()
        pitcherID = nil
        catcherID = nil
        lineup.removeAll()
        inningLineups.removeAll()
        inningPitcherIDs.removeAll()
        inningCatcherIDs.removeAll()
        battingOrderIDs.removeAll()
        designatedHitterID = nil
        designatedHitterForID = nil
        save()
    }
    
    func deleteAllPlayerData() {
        players = []
        coaches = []
        battingOrderIDs = []
        pitcherID = nil
        catcherID = nil
        lineup = [:]
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        designatedHitterID = nil
        designatedHitterForID = nil
        save()
    }
    func syncBattingOrder() {
        let existingIDs = Set(players.map { $0.id })
        battingOrderIDs.removeAll { !existingIDs.contains($0) }

        for player in players where !battingOrderIDs.contains(player.id) {
            battingOrderIDs.append(player.id)
        }
        save()
    }
    func player(for id: UUID) -> Player? {
        players.first { $0.id == id }
    }
    func moveBatters(from source: IndexSet, to destination: Int) {
        syncBattingOrder()
        battingOrderIDs.move(fromOffsets: source, toOffset: destination)
        save()
    }
}


