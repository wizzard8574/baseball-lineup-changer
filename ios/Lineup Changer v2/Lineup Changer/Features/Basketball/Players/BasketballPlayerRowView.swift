// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayerRowView.swift
//
//
//

import SwiftUI

// MARK: - Basketball Player Row
// Basketball roster row without baseball position-rating summaries.
struct BasketballPlayerRowView: View {
    let player: Player
    let viewModel: LineupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(PlayerDisplayHelper.baseDisplayLabel(for: player, showFullNameAndNumber: true))
                    .font(.headline)

                if let statusText = PlayerDisplayHelper.inlineStatusText(for: player) {
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(PlayerDisplayHelper.inlineStatusColor(for: player))
                }
            }

            PhoneContactMenu(number: player.cell)
                .font(.caption)

            if player.basketballPositionRatings.isEmpty {
                Text("No positions added")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(PlayerDisplayHelper.basketballPositionSummary(for: player))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let stats = player.basketballGameChangerStats {
                Text(stats.lineupDisplayText)
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
