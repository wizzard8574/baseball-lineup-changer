// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupActionsView.swift
//
//
//
import SwiftUI

// MARK: - Lineup Actions View
// Action button group for lineup generation and inning management.
struct LineupActionsView: View {
    // Shared lineup state and lineup generation methods.
    @ObservedObject var viewModel: LineupViewModel

    // Vertical stack of assignment automation and reset actions.
    var body: some View {
        VStack(spacing: 10) {
            // Automatically generate or fill defensive assignments.
            if viewModel.baseballUsesRosterBat {
                Button {
                    viewModel.assignLineup()
                } label: {
                    Label(viewModel.fallBallEnabled ? "Generate Fall Ball Lineups" : "Auto-Fill Positions", systemImage: "sparkles")
                        .labelStyle(.titleOnly)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

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
