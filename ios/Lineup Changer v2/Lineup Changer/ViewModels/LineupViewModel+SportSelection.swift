// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+SportSelection.swift
//
//
//
// Public sport-selection entry point used by app routing and setup screens.
import Foundation

// MARK: - Sport Selection
extension LineupViewModel {
    // Switches sport modes through one explicit path used by the UI.
    func selectSport(_ sport: SportType) {
        guard sport != selectedSport else { return }

        let oldSport = selectedSport
        isSelectingSport = true
        selectedSport = sport
        isSelectingSport = false

        switchSport(from: oldSport, to: sport)
    }
}
