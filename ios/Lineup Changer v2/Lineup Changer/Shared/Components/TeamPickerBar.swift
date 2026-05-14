// Created by Rich Morris on 5/5/26.
// Lineup Changer
// TeamPickerBar.swift
//
//
//
// TeamPickerBar.swift contains a reusable styled wrapper around TeamPickerView.
// It provides consistent spacing, background styling, and change callbacks for
// screens that need a floating team-selection control.
import SwiftUI

// MARK: - Team Picker Bar
// Styled container for the shared TeamPickerView.
struct TeamPickerBar: View {
    // Shared app state containing the selected team index and team names.
    @ObservedObject var viewModel: LineupViewModel
    // Callback triggered whenever the selected team changes.
    let onTeamChange: () -> Void

    // Main floating-style team picker layout.
    var body: some View {
        // VStack keeps the component extensible if future controls are added.
        VStack(alignment: .leading, spacing: 8) {
            // Shared segmented team picker used throughout the app.
            TeamPickerView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                // Rounded translucent background creates the floating toolbar appearance.
                .background(Color(uiColor: .systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(.horizontal, 32)
                // Notify the parent view whenever the selected team changes.
                .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                    onTeamChange()
                }
        }
    }
}
