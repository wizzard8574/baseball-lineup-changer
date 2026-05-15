// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayerDetailView+PositionSections.swift
//
//
//
import SwiftUI

// MARK: - Baseball Player Detail Position Sections
extension BaseballPlayerDetailView {
    var addPositionSection: some View {
        Section("Add or Update Position") {
            if availablePositions.isEmpty {
                Text("All positions already assigned.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Position", selection: $selectedPosition) {
                    ForEach(availablePositions) { position in
                        Text(position.rawValue).tag(position)
                    }
                }

                Picker("Rating", selection: $selectedRating) {
                    ForEach(1...5, id: \.self) { rating in
                        Text("\(rating)").tag(rating)
                    }
                }

                Button("Save Position") {
                    viewModel.setRating(playerID: player.id, position: selectedPosition, rating: selectedRating)
                    selectFirstAvailablePosition()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    var currentPositionsSection: some View {
        Section("Current Positions") {
            if let currentPlayer, currentPlayer.positionRatings.isEmpty {
                Text("No positions added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(FieldPosition.allCases) { position in
                    if let rating = currentPlayer?.positionRatings[position] {
                        currentPositionRow(position: position, rating: rating)
                    }
                }
            }
        }
    }

    private func currentPositionRow(position: FieldPosition, rating: Int) -> some View {
        HStack {
            Text(position.rawValue)
                .fontWeight(.semibold)

            Spacer()

            Picker("Rating", selection: Binding(
                get: { rating },
                set: { newRating in
                    viewModel.setRating(playerID: player.id, position: position, rating: newRating)
                }
            )) {
                ForEach(1...5, id: \.self) { rating in
                    Text("\(rating)").tag(rating)
                }
            }
            .pickerStyle(.segmented)
        }
        .swipeActions {
            Button("Remove", role: .destructive) {
                viewModel.removePosition(playerID: player.id, position: position)
            }
        }
    }

    var ratingScaleSection: some View {
        Section("Scale") {
            Text("1 = High, 5 = Low. A player is only considered for positions listed here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
