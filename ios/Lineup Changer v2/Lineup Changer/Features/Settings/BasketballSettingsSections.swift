// Created by Rich Morris on 5/14/26.
// Lineup Changer
// BasketballSettingsSections.swift
//
//
//
// BasketballSettingsSections contains basketball-only settings controls.
import SwiftUI

// MARK: - Basketball Settings Sections
struct BasketballSettingsSections: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        Section(header: SettingsSectionHeader(title: "Court Display")) {
            Toggle("Show Ratings", isOn: $viewModel.showRatingsOnCourt)
            Toggle("Show Assigned Lineup", isOn: $viewModel.showAssignedBasketballLineup)
            Toggle("Display First Name and Number", isOn: Binding(
                get: { !viewModel.showFullNameAndNumberInBasketball },
                set: { viewModel.showFullNameAndNumberInBasketball = !$0 }
            ))
            Toggle("Show Bench", isOn: $viewModel.showBasketballBenchOnCourt)

            VStack(alignment: .leading, spacing: 8) {
                Text("Game Format")
                    .font(.subheadline.weight(.semibold))

                Picker("Game Format", selection: $viewModel.basketballPeriodFormat) {
                    Text("4 Quarters").tag(BasketballPeriodFormat.quarters)
                    Text("2 Halves").tag(BasketballPeriodFormat.halves)
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
