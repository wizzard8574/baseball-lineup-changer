// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+BenchSection.swift
//
//
//
import SwiftUI

// MARK: - Bench Section
extension BaseballFieldView {
    var benchSection: some View {
        Section(header: fieldSectionHeader("Bench")) {
            let bench = benchPlayers()

            if let benchPlacementWarningText {
                Text(benchPlacementWarningText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }

            if bench.isEmpty {
                Text("No bench players")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(bench) { player in
                    HStack {
                        BaseballPlayerRowView(player: player, viewModel: viewModel)

                        Spacer()

                        if viewModel.baseballUsesRosterBat {
                            Button("Put In Field") {
                                if viewModel.placeBenchPlayerInField(playerID: player.id) {
                                    benchPlacementWarningText = nil
                                } else {
                                    benchPlacementWarningText = "Unable to put player in field without rating"
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Menu("Position") {
                                ForEach(FieldPosition.autoAssignedPositions) { position in
                                    Button("Move to \(position.rawValue)") {
                                        viewModel.updateFieldPosition(position, playerID: player.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
