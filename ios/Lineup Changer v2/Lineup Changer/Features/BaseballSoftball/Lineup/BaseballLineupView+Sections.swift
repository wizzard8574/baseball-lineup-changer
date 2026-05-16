// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Baseball Lineup Sections
extension BaseballLineupView {
    @ViewBuilder
    var lineupFormSections: some View {
        teamPickerSection
        printSaveSection
        if viewModel.baseballUsesNineBatterAndDH {
            lineupActionsSection
        }
        battingOrderSection

        if viewModel.baseballUsesNineBatterAndDH {
            benchSection
            designatedHitterSection
        }

        if hasImportedGameChangerStats {
            statsInfoSection
        }

        howItWorksSection
    }

    private var teamPickerSection: some View {
        lineupGroupedSection {
            TeamPickerView(viewModel: viewModel)
        }
    }

    private var lineupActionsSection: some View {
        lineupGroupedSection {
            Button(role: .destructive) {
                viewModel.clearBaseballLineupToBench()
            } label: {
                Label("Clear Lineup", systemImage: "arrow.down.to.line.compact")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        }
    }
}
