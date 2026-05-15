// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+AssignmentUpdates.swift
//
//
//
import Foundation

// MARK: - Assignment Updates
extension BaseballFieldView {
    func updatePitcherSelection(_ playerID: UUID?) {
        if let playerID {
            clearPlayerFromFieldPositions(playerID)

            if viewModel.catcherID == playerID {
                viewModel.updateFieldPosition(.catcher, playerID: nil)
            }
        }

        viewModel.updateFieldPosition(.pitcher, playerID: playerID)
    }

    func updateCatcherSelection(_ playerID: UUID?) {
        if let playerID {
            clearPlayerFromFieldPositions(playerID)

            if viewModel.pitcherID == playerID {
                viewModel.updateFieldPosition(.pitcher, playerID: nil)
            }
        }

        viewModel.updateFieldPosition(.catcher, playerID: playerID)
    }

    func updateAssignedLineupPosition(_ position: FieldPosition, playerID: UUID?) {
        if let playerID {
            if viewModel.pitcherID == playerID {
                viewModel.updatePitcher(nil)
            }

            if viewModel.catcherID == playerID {
                viewModel.updateCatcher(nil)
            }

            clearPlayerFromFieldPositions(playerID, except: position)
        }

        viewModel.updateFieldPosition(position, playerID: playerID)
    }

    func clearPlayerFromFieldPositions(_ playerID: UUID, except keptPosition: FieldPosition? = nil) {
        for position in FieldPosition.allCases {
            guard position != keptPosition else { continue }

            if viewModel.lineup[position] == playerID {
                viewModel.updateFieldPosition(position, playerID: nil)
            }
        }
    }
}
