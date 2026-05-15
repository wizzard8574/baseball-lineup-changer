// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+FallBall.swift
//
//
//

import Foundation

// MARK: - Fall Ball Generation
extension LineupViewModel {
    // MARK: - Fall Ball Generation
    // Generates all inning lineups using Fall Ball rules.
    func assignFallBallLineups() {
        // Nothing can be generated without eligible players.
        guard !activePlayers.isEmpty else { return }

        // Track play/bench counts so generated lineups can spread playing time.
        var playCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var benchCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var generatedLineups: [Int: [FieldPosition: UUID]] = [:]
        var generatedPitchers: [Int: UUID] = [:]
        var generatedCatchers: [Int: UUID] = [:]
        var usedFallBallPitcherIDs = Set<UUID>()

        // Generate a complete assignment for every inning.
        for inning in 1...numberOfInnings {
            // Youth mode randomizes all positions; standard mode keeps catcher manual and rotates pitchers.
            let assignment = fallBallYouthEnabled
                ? randomYouthFallBallAssignment(playCounts: &playCounts, benchCounts: &benchCounts)
                : randomFallBallAssignment(playCounts: &playCounts, benchCounts: &benchCounts, usedPitcherIDs: &usedFallBallPitcherIDs)

            // Store pitcher and catcher IDs separately for picker state and persistence.
            generatedLineups[inning] = assignment

            if let pitcherID = assignment[.pitcher] {
                generatedPitchers[inning] = pitcherID
            }

            if let catcherID = assignment[.catcher] {
                generatedCatchers[inning] = catcherID
            }
        }

        // Apply generated lineups and show inning 1 after generation completes.
        inningLineups = generatedLineups
        inningPitcherIDs = generatedPitchers
        inningCatcherIDs = generatedCatchers
        selectedInning = 1
        lineup = generatedLineups[1] ?? [:]
        pitcherID = generatedPitchers[1]
        catcherID = fallBallYouthEnabled ? generatedCatchers[1] : catcherID
        save()
    }
}
