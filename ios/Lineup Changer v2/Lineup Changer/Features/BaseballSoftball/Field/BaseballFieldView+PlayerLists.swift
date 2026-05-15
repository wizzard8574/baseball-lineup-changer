// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+PlayerLists.swift
//
//
//
import SwiftUI

// MARK: - Player Lists
extension BaseballFieldView {
    var sortedActivePlayers: [Player] {
        if viewModel.baseballUsesNineBatterAndDH {
            return viewModel.baseballDisplayedBatters
        }

        return viewModel.activePlayers.sorted { lhs, rhs in
            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)
            switch (lhsNumber, rhsNumber) {
            case let (l?, r?):
                return l < r
            case (nil, nil):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            }
        }
    }

    // Prevents the same player from being both pitcher and catcher simultaneously.
    var catcherPickerPlayers: [Player] {
        sortedActivePlayers.filter { player in
            player.id != viewModel.pitcherID
        }
    }

    func benchPlayers() -> [Player] {
        if viewModel.baseballUsesNineBatterAndDH {
            return viewModel.baseballBenchBatters
        }

        let assignedIDs = Set(viewModel.lineup.values)
        return sortedActivePlayers.filter { !assignedIDs.contains($0.id) }
    }
}
