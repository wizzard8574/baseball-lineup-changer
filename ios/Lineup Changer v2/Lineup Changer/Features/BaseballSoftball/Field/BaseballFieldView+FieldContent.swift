// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+FieldContent.swift
//
//
//
import SwiftUI

// MARK: - Field Content
extension BaseballFieldView {
    var fieldPreviewContent: some View {
        FieldPreviewView(
            lineup: viewModel.resolvedLineup,
            showRatings: viewModel.showRatingsOnField,
            showFullNameAndNumber: viewModel.showFullNameAndNumber,
            onPositionTap: { position in
                selectedFieldViewPosition = position
                isShowingFieldPositionPlayerPicker = true
            }
        )
        .confirmationDialog(
            selectedFieldViewPosition.map { "Choose Player for \(PlayerDisplayHelper.assignedLineupLabel(for: $0))" } ?? "Choose Player",
            isPresented: $isShowingFieldPositionPlayerPicker,
            titleVisibility: .visible
        ) {
            if let selectedFieldViewPosition {
                Button("Unassigned") {
                    updateAssignedLineupPosition(selectedFieldViewPosition, playerID: nil)
                }

                ForEach(sortedActivePlayers) { player in
                    Button(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)) {
                        updateAssignedLineupPosition(selectedFieldViewPosition, playerID: player.id)
                    }
                }
            }

            Button("Cancel", role: .cancel) { }
        }
    }

    var assignedLineupContent: some View {
        AssignedLineupView(
            lineup: viewModel.resolvedLineup,
            sortedPlayers: sortedActivePlayers,
            onUpdate: { position, playerID in
                updateAssignedLineupPosition(position, playerID: playerID)
            },
            labelProvider: { PlayerDisplayHelper.assignedLineupLabel(for: $0) },
            displayLabel: { PlayerDisplayHelper.displayLabel(for: $0, showFullNameAndNumber: viewModel.showFullNameAndNumber) },
            ratingLabel: { PlayerDisplayHelper.ratingLabel(for: $0, at: $1) }
        )
    }
}
