// Created by Rich Morris on 5/11/26.
// Lineup Changer
// LineupRouterView.swift
//
//
//
// LineupRouterView routes the Lineup tab to the selected sport's lineup screen.
import SwiftUI

// MARK: - Lineup Router View
struct LineupRouterView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            BaseballLineupView(viewModel: viewModel)
        case .basketball:
            BasketballLineupView(viewModel: viewModel)
        case .football, .volleyball, .soccer:
            lineupPlaceholderView
        }
    }

    private var lineupPlaceholderView: some View {
        SportFeaturePlaceholderView(
            title: viewModel.selectedSport.lineupPlaceholderTitle,
            message: viewModel.selectedSport.lineupPlaceholderMessage,
            toolbarTitle: "Lineup",
            toolbarIconName: "list.number",
            symbolName: "list.number"
        )
    }
}
