// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+DesignatedHitter.swift
//
//
//
import SwiftUI

// MARK: - Designated Hitter
extension BaseballLineupView {
    var designatedHitterSection: some View {
        lineupGroupedSection("Designated Hitter") {
            Picker("DH", selection: Binding(
                get: { viewModel.designatedHitterID },
                set: { viewModel.designatedHitterID = $0 }
            )) {
                Text("No DH selected").tag(UUID?.none)
                ForEach(viewModel.designatedHitterCandidates) { player in
                    Text(lineupDisplayLabel(for: player)).tag(Optional(player.id))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            lineupRowDivider

            Picker("DH For", selection: Binding(
                get: { viewModel.designatedHitterForID },
                set: { viewModel.designatedHitterForID = $0 }
            )) {
                Text("Select player").tag(UUID?.none)
                ForEach(viewModel.designatedHitterForCandidates) { player in
                    Text(lineupDisplayLabel(for: player)).tag(Optional(player.id))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            if let dhID = viewModel.designatedHitterID,
               let dh = viewModel.player(for: dhID) {
                lineupRowDivider
                designatedHitterSummaryRow(label: "DH", player: dh)
            }

            if let dhForID = viewModel.designatedHitterForID,
               let dhFor = viewModel.player(for: dhForID) {
                lineupRowDivider
                designatedHitterSummaryRow(label: "For", player: dhFor)
            }
        }
    }

    private func designatedHitterSummaryRow(label: String, player: Player) -> some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
                .frame(width: 34, alignment: .leading)

            Text(lineupDisplayLabel(for: player))

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }
}
