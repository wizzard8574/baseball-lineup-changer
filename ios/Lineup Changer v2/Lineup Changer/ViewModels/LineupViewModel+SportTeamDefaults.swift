// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+SportTeamDefaults.swift
//
//
//
import Foundation

// MARK: - Sport Team State
extension LineupViewModel {
    func defaultTeamNames(for sport: SportType) -> [String] {
        sport.defaultTeamNames
    }

    func normalizedTeamNames(_ names: [String], for sport: SportType) -> [String] {
        let defaults = defaultTeamNames(for: sport)
        return [
            names.indices.contains(0) && !names[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? names[0] : defaults[0],
            names.indices.contains(1) && !names[1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? names[1] : defaults[1]
        ]
    }

    func normalizedTeamSnapshots(_ snapshots: [TeamSnapshot], for sport: SportType) -> [TeamSnapshot] {
        let savedSnapshots = Array(snapshots.prefix(2))
        return savedSnapshots + Array(repeating: emptyTeamSnapshot(for: sport), count: max(0, 2 - savedSnapshots.count))
    }
}
