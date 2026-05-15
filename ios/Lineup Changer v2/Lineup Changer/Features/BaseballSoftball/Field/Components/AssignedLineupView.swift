//
//  AssignedLineupView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/8/26.
//
import SwiftUI

// MARK: - Assigned Lineup View
// Table-based field assignment editor.
// Provides a compact lineup management view using picker controls for every position.
struct AssignedLineupView: View {
    // Current field assignments keyed by defensive position.
    let lineup: [FieldPosition: Player]
    // Available players shown in each assignment picker.
    let sortedPlayers: [Player]
    // Callback fired whenever a picker changes assignment.
    let onUpdate: (FieldPosition, UUID?) -> Void
    // Provides the display label for each defensive position.
    let labelProvider: (FieldPosition) -> String
    // Provides the player display text used in picker menus.
    let displayLabel: (Player) -> String
    // Provides the formatted position rating label shown beside assigned players.
    let ratingLabel: (Player, FieldPosition) -> String

    private func pickerPlayers(for position: FieldPosition) -> [Player] {
        let currentPlayerID = lineup[position]?.id
        let assignedPlayerIDs = Set(lineup.compactMap { assignedPosition, player in
            assignedPosition == position ? nil : player.id
        })

        return sortedPlayers.filter { player in
            player.id == currentPlayerID || !assignedPlayerIDs.contains(player.id)
        }
    }

    // One editable row per defensive position.
    var body: some View {
        ForEach(FieldPosition.allCases) { position in
            // Position label, assignment picker, and optional rating display.
            HStack {
                Text(labelProvider(position))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(width: 64, alignment: .leading)

                Picker("", selection: Binding(
                    get: { lineup[position]?.id },
                    set: { newPlayerID in
                        // Notify the parent view about assignment changes.
                        onUpdate(position, newPlayerID)
                    }
                )) {
                    Text("Unassigned").tag(UUID?.none)
                    ForEach(pickerPlayers(for: position)) { player in
                        Text(displayLabel(player)).tag(Optional(player.id))
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                if let player = lineup[position] {
                    // Show the assigned player's rating for this defensive position.
                    Text(ratingLabel(player, position))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
