// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+FallBallAssignments.swift
//
//
//
// Fall Ball inning assignment and randomization helpers.
import Foundation

// MARK: - Fall Ball Assignments
extension LineupViewModel {
    // Builds one standard Fall Ball inning assignment.
    // Pitcher is selected from rated pitchers and rotated when possible; catcher stays manual.
    func randomFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int], usedPitcherIDs: inout Set<UUID>) -> [FieldPosition: UUID] {
        // Track used players so a player is not assigned to multiple positions in the same inning.
        var assignments: [FieldPosition: UUID] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        // Pitcher pool includes only players with a pitcher rating.
        let availablePitchers = eligiblePlayers.filter { $0.positionRatings[.pitcher] != nil }
        let pitcherCandidates = availablePitchers.filter { !usedPitcherIDs.contains($0.id) }
        let selectedPitcher = playersByFewestPlays(
            pitcherCandidates.isEmpty ? availablePitchers : pitcherCandidates,
            playCounts: playCounts
        ).first

        // Assign the selected pitcher and record that they have pitched.
        if let pitcher = selectedPitcher {
            assignments[.pitcher] = pitcher.id
            usedPlayerIDs.insert(pitcher.id)
            usedPitcherIDs.insert(pitcher.id)
            playCounts[pitcher.id, default: 0] += 1
        }

        // Standard Fall Ball keeps the manually selected catcher when available.
        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher.id
            usedPlayerIDs.insert(catcher.id)
            playCounts[catcher.id, default: 0] += 1
        }

        // Fill remaining auto-assigned positions while favoring players with fewer plays.
        for position in shuffledForLineup(FieldPosition.autoAssignedPositions) {
            // Candidate must be unused this inning and rated for the position.
            let candidates = playersByFewestPlays(
                eligiblePlayers
                .filter { player in
                    !usedPlayerIDs.contains(player.id) && player.positionRatings[position] != nil
                },
                playCounts: playCounts
            )

            // Assign the best candidate and increment their play count.
            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer.id
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        // Anyone not used this inning receives a bench count.
        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    // Builds one youth Fall Ball inning assignment.
    // Youth mode allows every position, including pitcher and catcher, to be randomized.
    func randomYouthFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int]) -> [FieldPosition: UUID] {
        // Track assignments and player usage for this one inning.
        var assignments: [FieldPosition: UUID] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        // Shuffle positions so assignment order varies between innings.
        for position in shuffledForLineup(FieldPosition.allCases) {
            // Prefer players with fewer plays so time is distributed more evenly.
            let candidates = playersByFewestPlays(
                eligiblePlayers.filter { !usedPlayerIDs.contains($0.id) },
                playCounts: playCounts
            )

            // Assign the chosen player and increment their play count.
            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer.id
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    // Updates bench counts for players who did not receive a field assignment this inning.
    func updateBenchCounts(usedPlayerIDs: Set<UUID>, benchCounts: inout [UUID: Int]) {
        for player in activePlayers where !usedPlayerIDs.contains(player.id) {
            benchCounts[player.id, default: 0] += 1
        }
    }

    // Returns a shuffled copy using the injected random source.
    func shuffledForLineup<Element>(_ elements: [Element]) -> [Element] {
        guard elements.count > 1 else { return elements }

        var result = elements
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let swapIndex = safeRandomIndex(upperBound: index + 1)
            if swapIndex != index {
                result.swapAt(index, swapIndex)
            }
        }
        return result
    }

    // Keeps injected random output inside the bounds required by shuffle.
    func safeRandomIndex(upperBound: Int) -> Int {
        guard upperBound > 1 else { return 0 }
        return min(max(lineupRandomIndex(upperBound), 0), upperBound - 1)
    }

    // Sorts by fewest plays, using a random pre-shuffle as the deterministic tie breaker.
    func playersByFewestPlays(_ players: [Player], playCounts: [UUID: Int]) -> [Player] {
        let shuffledPlayers = shuffledForLineup(players)
        let randomRanks = Dictionary(uniqueKeysWithValues: shuffledPlayers.enumerated().map { offset, player in
            (player.id, offset)
        })

        return shuffledPlayers.sorted { lhs, rhs in
            let lhsPlays = playCounts[lhs.id, default: 0]
            let rhsPlays = playCounts[rhs.id, default: 0]

            if lhsPlays == rhsPlays {
                return randomRanks[lhs.id, default: 0] < randomRanks[rhs.id, default: 0]
            }

            return lhsPlays < rhsPlays
        }
    }
}
