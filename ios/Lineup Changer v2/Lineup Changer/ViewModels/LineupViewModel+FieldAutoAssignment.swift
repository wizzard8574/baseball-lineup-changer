// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+FieldAutoAssignment.swift
//
//
//
// Standard automatic field lineup assignment.
import Foundation

// MARK: - Standard Auto Assignment
extension LineupViewModel {
    // Builds the current inning lineup.
    // In Fall Ball mode this delegates to the Fall Ball generator; otherwise it keeps
    // manual pitcher/catcher choices and fills remaining positions by best rating.
    func assignLineup() {
        if fallBallRunRuleEnabled {
            assignRunRuleLineup()
            return
        }

        // Fall Ball creates lineups across all innings at once.
        if fallBallEnabled {
            assignFallBallLineups()
            return
        }

        // Track assignments and prevent any player from being used twice.
        var assignments: [FieldPosition: UUID] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = baseballUsesNineBatterAndDH ? baseballDisplayedBatters : activePlayers

        // Preserve manually selected pitcher when that player is still eligible.
        if let pitcher = eligiblePlayers.first(where: { $0.id == pitcherID }) {
            assignments[.pitcher] = pitcher.id
            usedPlayerIDs.insert(pitcher.id)
        }

        // Preserve manually selected catcher when that player is still eligible and not already pitching.
        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher.id
            usedPlayerIDs.insert(catcher.id)
        }

        // Fills the remaining field positions using the best available rating.
        // 1 is best, 5 is worst.
        // Players are only considered for positions entered on their profile.
        for position in FieldPosition.autoAssignedPositions {
            let bestAvailable = eligiblePlayers
                .filter { player in
                    !usedPlayerIDs.contains(player.id) && player.positionRatings[position] != nil
                }
                .sorted { lhs, rhs in
                    let lhsRating = lhs.positionRatings[position] ?? 99
                    let rhsRating = rhs.positionRatings[position] ?? 99

                    if lhsRating == rhsRating {
                        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    }

                    return lhsRating < rhsRating
                }
                .first

            if let bestAvailable {
                assignments[position] = bestAvailable.id
                usedPlayerIDs.insert(bestAvailable.id)
            }
        }

        // Apply generated assignments, save this inning, and carry it forward if needed.
        lineup = assignments
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    private func assignRunRuleLineup() {
        var assignments: [FieldPosition: UUID] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        if let pitcher = eligiblePlayers.first(where: { $0.id == pitcherID }) {
            assignments[.pitcher] = pitcher.id
            usedPlayerIDs.insert(pitcher.id)
        }

        let positionsToFill = shuffledForLineup(FieldPosition.allCases.filter { position in
            assignments[position] == nil
        })

        for position in positionsToFill {
            let candidates = shuffledForLineup(eligiblePlayers.filter { player in
                guard !usedPlayerIDs.contains(player.id),
                      let rating = player.positionRatings[position] else { return false }

                return rating != 1
            })

            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer.id
                usedPlayerIDs.insert(selectedPlayer.id)
            }
        }

        lineup = assignments
        pitcherID = assignments[.pitcher]
        catcherID = assignments[.catcher]
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
}
