// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Defaults.swift
//
//
//
// Small UserDefaults-backed startup defaults.
import Foundation

// MARK: - Defaults Helpers
extension LineupViewModel {
    // UserDefaults key for the inning count setting.
    static let numberOfInningsDefaultsKey = "numberOfInnings"

    // Loads the saved inning count, defaulting to seven if no valid value exists.
    static func loadSavedNumberOfInnings(from userDefaults: UserDefaults) -> Int {
        // UserDefaults returns 0 when the key has never been set.
        let saved = userDefaults.integer(forKey: numberOfInningsDefaultsKey)
        return (1...12).contains(saved) ? saved : 7
    }
}
