// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayersView+Helpers.swift
//
//
//
import SwiftUI

// MARK: - Basketball Players Helpers
extension BasketballPlayersView {
    var basketballTitle: some View {
        AppToolbarTitle(title: "Players", systemImage: "basketball.fill")
    }

    func addCoach() {
        let trimmedName = newCoachName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let coach = viewModel.addCoach(name: trimmedName) {
            newCoachDraft = coach
        }

        newCoachName = ""
        focusedField = nil
    }

    func addPlayer() {
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let player = viewModel.addPlayer(name: trimmedName) {
            newPlayerDraft = player
        }

        newPlayerName = ""
        focusedField = nil
    }

    func basketballSectionHeader(_ title: String) -> some View {
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
