// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayersView+Sorting.swift
//
//
//
import Foundation

// MARK: - Basketball Player Sorting
extension BasketballPlayersView {
    var sortedCoaches: [Coach] {
        viewModel.coaches.sorted { lhs, rhs in
            let lhsIsHeadCoach = lhs.role == "Head Coach"
            let rhsIsHeadCoach = rhs.role == "Head Coach"

            if lhsIsHeadCoach != rhsIsHeadCoach {
                return lhsIsHeadCoach
            }

            return compareNumericLabels(
                lhsNumber: lhs.number,
                rhsNumber: rhs.number,
                lhsName: lhs.name,
                rhsName: rhs.name
            )
        }
    }

    var sortedPlayers: [Player] {
        viewModel.players.sorted { lhs, rhs in
            if lhs.status == .guest && rhs.status != .guest { return false }
            if rhs.status == .guest && lhs.status != .guest { return true }

            if let gameChangerSortStat,
               let comparison = compareGameChangerStats(lhs, rhs, stat: gameChangerSortStat) {
                return comparison
            }

            return compareNumericLabels(
                lhsNumber: lhs.number,
                rhsNumber: rhs.number,
                lhsName: lhs.name,
                rhsName: rhs.name
            )
        }
    }

    private func compareNumericLabels(lhsNumber: String, rhsNumber: String, lhsName: String, rhsName: String) -> Bool {
        let lhsNumber = Int(lhsNumber)
        let rhsNumber = Int(rhsNumber)

        switch (lhsNumber, rhsNumber) {
        case let (l?, r?):
            return l < r
        case (nil, nil):
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        }
    }

    private func compareGameChangerStats(_ lhs: Player, _ rhs: Player, stat: BasketballGameChangerPlayerSortStat) -> Bool? {
        let lhsValue = gameChangerSortValue(for: lhs, stat: stat)
        let rhsValue = gameChangerSortValue(for: rhs, stat: stat)

        switch (lhsValue, rhsValue) {
        case let (lhs?, rhs?):
            if lhs == rhs { return nil }
            return stat == .topg ? lhs < rhs : lhs > rhs
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return nil
        }
    }

    private func gameChangerSortValue(for player: Player, stat: BasketballGameChangerPlayerSortStat) -> Double? {
        guard let stats = player.basketballGameChangerStats else { return nil }

        let rawValue: String
        switch stat {
        case .ppg:
            rawValue = stats.ppg
        case .topg:
            rawValue = stats.topg
        case .rpg:
            rawValue = stats.rpg
        case .apg:
            rawValue = stats.apg
        case .spg:
            rawValue = stats.spg
        case .bpg:
            rawValue = stats.bpg
        case .trueShootingPercentage:
            rawValue = stats.trueShootingPercentage
        case .assistTurnoverRatio:
            rawValue = stats.assistTurnoverRatio
        }

        let cleanedValue = rawValue.filter { character in
            character.isNumber || character == "." || character == "-"
        }

        return Double(cleanedValue)
    }
}
