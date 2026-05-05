//
//  PlayerRowView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import SwiftUI

struct PlayerRowView: View {
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

            if player.positionRatings.isEmpty {
                Text("No positions added")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(PlayerDisplayHelper.positionSummary(for: player))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
