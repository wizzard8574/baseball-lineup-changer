// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayerRowView.swift
//
//
//
import SwiftUI


// MARK: - Player Row View

// Compact roster row for one player.
// Shows the player label, status, phone contact menu, and defensive position summary.

struct BaseballPlayerRowView: View {
    // Player model rendered by this row.
    let player: Player
    // Shared view model used by row actions.
    let viewModel: LineupViewModel

    // Main row layout.
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Player label and optional inline status sit on the first line.
            HStack(spacing: 4) {
                // Use base label here because inline status is rendered separately.
                Text(PlayerDisplayHelper.baseDisplayLabel(for: player, showFullNameAndNumber: true))
                    .font(.headline)

                // Active players omit status text to keep the row clean.
                if let statusText = PlayerDisplayHelper.inlineStatusText(for: player) {
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(PlayerDisplayHelper.inlineStatusColor(for: player))
                }
            }

            // Reusable call/text menu for the player's cell number.
            PhoneContactMenu(number: player.cell)
                .font(.caption)

            // Show either a no-positions placeholder or a compact rating summary.
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
