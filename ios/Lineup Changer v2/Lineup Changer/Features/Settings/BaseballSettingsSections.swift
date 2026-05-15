// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballSettingsSections.swift
//
//
//
// BaseballSettingsSections contains baseball/softball-only settings controls.
import SwiftUI

// MARK: - Baseball Settings Sections
// Field, batting-order, and game format settings that only apply to baseball/softball.
struct BaseballSettingsSections: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        // Field and lineup display preferences.
        Section(header: SettingsSectionHeader(title: "Field Display")) {
            Toggle("Show Ratings", isOn: $viewModel.showRatingsOnField)
            Toggle("Show Assigned Lineup", isOn: $viewModel.showAssignedLineupTable)
            Toggle("Display First Name and Number", isOn: Binding(
                get: { !viewModel.showFullNameAndNumber },
                set: { viewModel.showFullNameAndNumber = !$0 }
            ))
            Toggle("Show Bench", isOn: $viewModel.showBenchOnField)

            Toggle("Fall Ball", isOn: $viewModel.fallBallEnabled)
                .disabled(viewModel.baseballUsesNineBatterAndDH)
            Toggle("Run Rule", isOn: $viewModel.fallBallRunRuleEnabled)
                .disabled(viewModel.baseballUsesNineBatterAndDH)

            if viewModel.fallBallEnabled {
                Toggle("Youth", isOn: $viewModel.fallBallYouthEnabled)
                    .disabled(viewModel.baseballUsesNineBatterAndDH)
            }

            // Inning count is clamped to the supported 1...12 range elsewhere as well.
            Stepper(
                "Number of Innings: \(viewModel.numberOfInnings)",
                value: $viewModel.numberOfInnings,
                in: 1...12
            )
        }

        // Batting order display and warning preferences.
        Section(header: SettingsSectionHeader(title: "Batting Order")) {
            Toggle("Roster Bat", isOn: $viewModel.showOnlyNineBattersAndDH)
            Toggle("Warn when No Steal P/C Bats After No Steal Runner", isOn: $viewModel.showSlowSpeedBattingWarnings)
        }
    }
}
