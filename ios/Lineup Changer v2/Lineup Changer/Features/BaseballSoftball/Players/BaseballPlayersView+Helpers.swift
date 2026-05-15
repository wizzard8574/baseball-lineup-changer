// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView+Helpers.swift
//
//
//
import SwiftUI

// MARK: - Baseball Players View Helpers
extension BaseballPlayersView {
    var playersTitle: some View {
        AppToolbarTitle(title: "Players", systemImage: "person.3.fill")
    }

    // MARK: - Actions
    func addCoach() {
        // Trim and validate before creating the coach.
        let trimmedName = newCoachName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Open the newly created coach detail screen immediately.
        if let coach = viewModel.addCoach(name: trimmedName) {
            newCoachDraft = coach
        }

        newCoachName = ""
        focusedField = nil
    }

    func addPlayer() {
        // Trim and validate before creating the player.
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Open the newly created player detail screen immediately.
        if let player = viewModel.addPlayer(name: trimmedName) {
            newPlayerDraft = player
        }

        newPlayerName = ""
        focusedField = nil
    }

    // MARK: - Section Header Styling
    // Shared styling helper for roster section headers.
    func playersSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }
}
