// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+LineupActionsSection.swift
//
//
//
import SwiftUI

// MARK: - Lineup Actions Section
extension BaseballFieldView {
    var lineupActionsSection: some View {
        Section(header: fieldSectionHeader("Lineup Actions")) {
            LineupActionsView(viewModel: viewModel)
        }
    }
}
