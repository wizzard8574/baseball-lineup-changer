//
//  LineupViewModel+Field.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/4/26.
//

import Foundation

extension LineupViewModel {
    // Field-related LineupViewModel logic will live here.
    
    func assignLineup() {
        if fallBallEnabled {
            assignFallBallLineups()
            return
        }
        
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers
        
        if let pitcher = eligiblePlayers.first(where: { $0.id == pitcherID }) {
            assignments[.pitcher] = pitcher
            usedPlayerIDs.insert(pitcher.id)
        }
        
        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher
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
                assignments[position] = bestAvailable
                usedPlayerIDs.insert(bestAvailable.id)
            }
        }
        
        lineup = assignments
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
    
    func setCurrentLineupForAllInnings() {
        saveCurrentInningState()
        
        for inning in 1...numberOfInnings {
            inningLineups[inning] = lineup
            
            if let pitcherID {
                inningPitcherIDs[inning] = pitcherID
            } else {
                inningPitcherIDs.removeValue(forKey: inning)
            }
            
            if let catcherID {
                inningCatcherIDs[inning] = catcherID
            } else {
                inningCatcherIDs.removeValue(forKey: inning)
            }
        }
        
        save()
    }
    
    func clearInning() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups[selectedInning] = [:]
        inningPitcherIDs.removeValue(forKey: selectedInning)
        inningCatcherIDs.removeValue(forKey: selectedInning)
        save()
    }
    
    func clearAllInnings() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        save()
    }
    
    func updateFieldPosition(_ position: FieldPosition, playerID: UUID?) {
        if position == .pitcher {
            updatePitcher(playerID)
            if let playerID, let player = activePlayers.first(where: { $0.id == playerID }) {
                lineup[.pitcher] = player
            } else {
                lineup.removeValue(forKey: .pitcher)
            }
            saveCurrentInningState()
            copyCurrentInningForwardIfNeeded()
            save()
            return
        }
        
        if position == .catcher {
            updateCatcher(playerID)
            if let playerID, let player = activePlayers.first(where: { $0.id == playerID }) {
                lineup[.catcher] = player
            } else {
                lineup.removeValue(forKey: .catcher)
            }
            saveCurrentInningState()
            copyCurrentInningForwardIfNeeded()
            save()
            return
        }
        
        if let playerID {
            guard let player = activePlayers.first(where: { $0.id == playerID }) else { return }
            
            lineup = lineup.filter { existingPosition, existingPlayer in
                existingPosition == position || existingPlayer.id != playerID
            }
            lineup[position] = player
        } else {
            lineup.removeValue(forKey: position)
        }
        
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
    
    /// Places a bench player into the field in the best open/rated position.
    func placeBenchPlayerInField(playerID: UUID) {
        guard let player = activePlayers.first(where: { $0.id == playerID }) else { return }
        
        lineup = lineup.filter { _, existingPlayer in
            existingPlayer.id != playerID
        }
        
        let ratedPositions = FieldPosition.autoAssignedPositions
            .filter { player.positionRatings[$0] != nil }
            .sorted { lhs, rhs in
                let lhsRating = player.positionRatings[lhs] ?? 99
                let rhsRating = player.positionRatings[rhs] ?? 99
                
                if lhsRating == rhsRating {
                    return lhs.rawValue < rhs.rawValue
                }
                
                return lhsRating < rhsRating
            }
        
        if let openRatedPosition = ratedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openRatedPosition] = player
        } else if let bestRatedPosition = ratedPositions.first {
            lineup[bestRatedPosition] = player
        } else if let openPosition = FieldPosition.autoAssignedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openPosition] = player
        } else if let fallbackPosition = FieldPosition.autoAssignedPositions.first {
            lineup[fallbackPosition] = player
        }
        
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
    
    func assignFallBallLineups() {
        guard !activePlayers.isEmpty else { return }

        var playCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var benchCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var generatedLineups: [Int: [FieldPosition: Player]] = [:]
        var generatedPitchers: [Int: UUID] = [:]
        var generatedCatchers: [Int: UUID] = [:]
        var usedFallBallPitcherIDs = Set<UUID>()

        for inning in 1...numberOfInnings {
            let assignment = fallBallYouthEnabled
                ? randomYouthFallBallAssignment(playCounts: &playCounts, benchCounts: &benchCounts)
                : randomFallBallAssignment(playCounts: &playCounts, benchCounts: &benchCounts, usedPitcherIDs: &usedFallBallPitcherIDs)

            generatedLineups[inning] = assignment

            if let pitcher = assignment[.pitcher] {
                generatedPitchers[inning] = pitcher.id
            }

            if let catcher = assignment[.catcher] {
                generatedCatchers[inning] = catcher.id
            }
        }

        inningLineups = generatedLineups
        inningPitcherIDs = generatedPitchers
        inningCatcherIDs = generatedCatchers
        selectedInning = 1
        lineup = generatedLineups[1] ?? [:]
        pitcherID = generatedPitchers[1]
        catcherID = fallBallYouthEnabled ? generatedCatchers[1] : catcherID
        save()
    }

    private func randomFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int], usedPitcherIDs: inout Set<UUID>) -> [FieldPosition: Player] {
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        let availablePitchers = eligiblePlayers.filter { $0.positionRatings[.pitcher] != nil }
        let pitcherCandidates = availablePitchers.filter { !usedPitcherIDs.contains($0.id) }
        let selectedPitcher = (pitcherCandidates.isEmpty ? availablePitchers : pitcherCandidates)
            .shuffled()
            .sorted { lhs, rhs in
                playCounts[lhs.id, default: 0] < playCounts[rhs.id, default: 0]
            }
            .first

        if let pitcher = selectedPitcher {
            assignments[.pitcher] = pitcher
            usedPlayerIDs.insert(pitcher.id)
            usedPitcherIDs.insert(pitcher.id)
            playCounts[pitcher.id, default: 0] += 1
        }

        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher
            usedPlayerIDs.insert(catcher.id)
            playCounts[catcher.id, default: 0] += 1
        }

        for position in FieldPosition.autoAssignedPositions.shuffled() {
            let candidates = eligiblePlayers
                .filter { player in
                    !usedPlayerIDs.contains(player.id) && player.positionRatings[position] != nil
                }
                .sorted { lhs, rhs in
                    let lhsPlays = playCounts[lhs.id, default: 0]
                    let rhsPlays = playCounts[rhs.id, default: 0]

                    if lhsPlays == rhsPlays {
                        return Bool.random()
                    }

                    return lhsPlays < rhsPlays
                }

            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    private func randomYouthFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int]) -> [FieldPosition: Player] {
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        for position in FieldPosition.allCases.shuffled() {
            let candidates = eligiblePlayers
                .filter { !usedPlayerIDs.contains($0.id) }
                .sorted { lhs, rhs in
                    let lhsPlays = playCounts[lhs.id, default: 0]
                    let rhsPlays = playCounts[rhs.id, default: 0]

                    if lhsPlays == rhsPlays {
                        return Bool.random()
                    }

                    return lhsPlays < rhsPlays
                }

            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    private func updateBenchCounts(usedPlayerIDs: Set<UUID>, benchCounts: inout [UUID: Int]) {
        for player in activePlayers where !usedPlayerIDs.contains(player.id) {
            benchCounts[player.id, default: 0] += 1
        }
    }

    func selectInning(_ inning: Int) {
        saveCurrentInningState()
        selectedInning = min(max(inning, 1), numberOfInnings)

        if inningLineups[selectedInning] == nil, selectedInning > 1 {
            inningLineups[selectedInning] = inningLineups[selectedInning - 1] ?? lineup
            inningPitcherIDs[selectedInning] = inningPitcherIDs[selectedInning - 1]
            inningCatcherIDs[selectedInning] = inningCatcherIDs[selectedInning - 1]
        }

        lineup = inningLineups[selectedInning] ?? [:]
        pitcherID = inningPitcherIDs[selectedInning]
        catcherID = inningCatcherIDs[selectedInning]
        save()
    }

    func saveCurrentInningState() {
        inningLineups[selectedInning] = lineup

        if let pitcherID {
            inningPitcherIDs[selectedInning] = pitcherID
        } else {
            inningPitcherIDs.removeValue(forKey: selectedInning)
        }

        if let catcherID {
            inningCatcherIDs[selectedInning] = catcherID
        } else {
            inningCatcherIDs.removeValue(forKey: selectedInning)
        }
    }

    func updatePitcher(_ playerID: UUID?) {
        pitcherID = playerID
        if catcherID == playerID { catcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    func updateCatcher(_ playerID: UUID?) {
        catcherID = playerID
        if pitcherID == playerID { pitcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    func copyCurrentInningForwardIfNeeded() {
        guard selectedInning < numberOfInnings else { return }

        for inning in (selectedInning + 1)...numberOfInnings {
            if inningLineups[inning] == nil || inningLineups[inning]?.isEmpty == true {
                inningLineups[inning] = lineup
                inningPitcherIDs[inning] = pitcherID
                inningCatcherIDs[inning] = catcherID
            }
        }
    }
}
