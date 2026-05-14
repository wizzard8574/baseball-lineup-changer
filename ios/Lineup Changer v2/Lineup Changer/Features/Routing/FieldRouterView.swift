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

// MARK: - FieldRouterView View
// Main Field tab router.
struct FieldRouterView: View {
    // Shared application state and lineup management logic.
    @ObservedObject var viewModel: LineupViewModel

    // Switches between sport-specific field/court implementations.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            BaseballFieldView(viewModel: viewModel)
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

