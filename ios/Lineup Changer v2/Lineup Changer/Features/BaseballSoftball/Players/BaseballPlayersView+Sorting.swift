// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView+Sorting.swift
//
//
//
import Foundation

// MARK: - Baseball Players Sorting
extension BaseballPlayersView {
    // Coaches sort with Head Coach first, then by numeric number, then by name.
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

    // Players sort by status first, then numeric number, then name.
    var sortedPlayers: [Player] {
        viewModel.players.sorted { lhs, rhs in
            if lhs.status == .guest && rhs.status != .guest { return false }
            if rhs.status == .guest && lhs.status != .guest { return true }

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
}
