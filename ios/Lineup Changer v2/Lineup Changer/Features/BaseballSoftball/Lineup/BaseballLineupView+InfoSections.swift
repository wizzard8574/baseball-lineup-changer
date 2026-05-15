// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+InfoSections.swift
//
//
//
import SwiftUI

// MARK: - Info Sections
extension BaseballLineupView {
    var howItWorksSection: some View {
        lineupGroupedSection("How this works") {
            Text(viewModel.baseballUsesNineBatterAndDH ? "Roster Bat is off. Clear the lineup to move everyone to the bench, then drag players between Batting Order and Bench. The lineup is limited to 9 batters and can use a DH." : "Roster Bat is on. All active roster players are shown in the batting order. Use Edit to reorder them.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
        }
    }
}
