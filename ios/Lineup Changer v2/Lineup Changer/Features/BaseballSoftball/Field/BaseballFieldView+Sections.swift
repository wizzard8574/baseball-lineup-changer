// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballFieldView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Field Sections
extension BaseballFieldView {
    @ViewBuilder
    var fieldFormSections: some View {
        teamPickerSection
        inningPickerSection

        if !viewModel.fallBallYouthEnabled {
            manualPositionsSection
        }

        lineupActionsSection
        fieldAndAssignedLineupSections

        if viewModel.showBenchOnField {
            benchSection
        }

        assignmentInfoSection
    }

    private var teamPickerSection: some View {
        Section {
            TeamPickerView(viewModel: viewModel)
        }
    }
}
