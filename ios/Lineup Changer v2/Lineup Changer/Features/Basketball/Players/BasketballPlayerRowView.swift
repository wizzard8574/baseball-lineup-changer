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
                Text(PlayerDisplayHelper.baseDisplayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber))
                    .font(.headline)

                if let statusText = PlayerDisplayHelper.inlineStatusText(for: player) {
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(PlayerDisplayHelper.inlineStatusColor(for: player))
                }
            }

            PhoneContactMenu(number: player.cell)
                .font(.caption)

            Text("Basketball roster")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
