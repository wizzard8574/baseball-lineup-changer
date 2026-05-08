// Created by Rich Morris on 5/5/26.
// Lineup Changer
// FieldView.swift
//
//
//
// FieldView.swift routes the Field tab to the active sport-specific surface.
// Shared field-assignment controls stay here while each sport owns its own
// field/court implementation file.
import SwiftUI

// MARK: - Assignment View
// Main Field tab router.
struct AssignmentView: View {
    // Shared application state and lineup management logic.
    @ObservedObject var viewModel: LineupViewModel

    // Switches between sport-specific field/court implementations.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            BaseballSoftballFieldView(viewModel: viewModel)
        case .basketball:
            BasketballCourtView(viewModel: viewModel)
        case .football:
            FootballFieldView(viewModel: viewModel)
        case .volleyball:
            VolleyballCourtView(viewModel: viewModel)
        case .soccer:
            SoccerFieldView(viewModel: viewModel)
        }
    }
}

// MARK: - Lineup Actions View
// Action button group for lineup generation and inning management.
struct LineupActionsView: View {
    // Shared lineup state and lineup generation methods.
    @ObservedObject var viewModel: LineupViewModel

    // Vertical stack of assignment automation and reset actions.
    var body: some View {
        VStack(spacing: 10) {
            // Automatically generate or fill defensive assignments.
            Button {
                viewModel.assignLineup()
            } label: {
                Label(viewModel.fallBallEnabled ? "Generate Fall Ball Lineups" : "Auto-Fill Positions", systemImage: "sparkles")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Copies the current inning lineup into every inning.
            Button {
                viewModel.setCurrentLineupForAllInnings()
            } label: {
                Label("Use This Lineup for All Innings", systemImage: "square.stack.3d.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            // Destructive reset actions for inning cleanup.
            HStack(spacing: 10) {
                Button(role: .destructive) {
                    viewModel.clearInning()
                } label: {
                    Label("Clear Inning", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    viewModel.clearAllInnings()
                } label: {
                    Label("Clear All", systemImage: "trash.slash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }
}


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
                    ForEach(sortedPlayers) { player in
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
