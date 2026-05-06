// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+Field.swift
//
//
//
// Field-related LineupViewModel functionality.
// This extension manages defensive assignments, inning state, standard auto-fill,
// Fall Ball lineup generation, pitcher/catcher updates, and bench placement.
import Foundation

// MARK: - Field Assignment Management
extension LineupViewModel {
    // MARK: - Standard Auto Assignment
    
    // Builds the current inning lineup.
    // In Fall Ball mode this delegates to the Fall Ball generator; otherwise it keeps
    // manual pitcher/catcher choices and fills remaining positions by best rating.
    func assignLineup() {
        // Fall Ball creates lineups across all innings at once.
        if fallBallEnabled {
            assignFallBallLineups()
            return
        }
        
        // Track assignments and prevent any player from being used twice.
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers
        
        // Preserve manually selected pitcher when that player is still eligible.
        if let pitcher = eligiblePlayers.first(where: { $0.id == pitcherID }) {
            assignments[.pitcher] = pitcher
            usedPlayerIDs.insert(pitcher.id)
        }
        
        // Preserve manually selected catcher when that player is still eligible and not already pitching.
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
        
        // Apply generated assignments, save this inning, and carry it forward if needed.
        lineup = assignments
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
    
    // MARK: - Inning Copy / Clear Actions
    // Copies the currently visible lineup and pitcher/catcher selections to every inning.
    func setCurrentLineupForAllInnings() {
        // Ensure the current inning is stored before duplicating it.
        saveCurrentInningState()
        
        // Replace every inning with the current field state.
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
    
    // Clears only the selected inning's lineup and battery assignments.
    func clearInning() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups[selectedInning] = [:]
        inningPitcherIDs.removeValue(forKey: selectedInning)
        inningCatcherIDs.removeValue(forKey: selectedInning)
        save()
    }
    
    // Clears all inning lineups and all saved pitcher/catcher assignments.
    func clearAllInnings() {
        lineup = [:]
        pitcherID = nil
        catcherID = nil
        inningLineups = [:]
        inningPitcherIDs = [:]
        inningCatcherIDs = [:]
        save()
    }
    
    // MARK: - Manual Field Position Updates
    // Updates one defensive position and keeps inning state synchronized.
    func updateFieldPosition(_ position: FieldPosition, playerID: UUID?) {
        // Pitcher updates also update the dedicated pitcherID state.
        if position == .pitcher {
            updatePitcher(playerID)
            // Mirror pitcher assignment into the lineup dictionary for field display.
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
        
        // Catcher updates also update the dedicated catcherID state.
        if position == .catcher {
            updateCatcher(playerID)
            // Mirror catcher assignment into the lineup dictionary for field display.
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
        
        // Standard field positions store only in the lineup dictionary.
        if let playerID {
            // Ignore assignments for players who are no longer active or guest-eligible.
            guard let player = activePlayers.first(where: { $0.id == playerID }) else { return }
            
            // Remove this player from any other position before assigning the new one.
            lineup = lineup.filter { existingPosition, existingPlayer in
                existingPosition == position || existingPlayer.id != playerID
            }
            lineup[position] = player
        } else {
            lineup.removeValue(forKey: position)
        }
        
        // Persist and forward-fill this manual change when later innings are still empty.
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
    
    // MARK: - Bench Placement
    // Places a bench player into the field in the best open/rated position.
    func placeBenchPlayerInField(playerID: UUID) {
        // Only active or guest players can be placed in the field.
        guard let player = activePlayers.first(where: { $0.id == playerID }) else { return }
        
        // Remove the player from any existing field slot before finding a new one.
        lineup = lineup.filter { _, existingPlayer in
            existingPlayer.id != playerID
        }
        
        // Prefer the player's rated positions, sorted best rating first.
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
        
        // Choose the best open rated position, then progressively fall back if needed.
        if let openRatedPosition = ratedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openRatedPosition] = player
        } else if let bestRatedPosition = ratedPositions.first {
            lineup[bestRatedPosition] = player
        } else if let openPosition = FieldPosition.autoAssignedPositions.first(where: { lineup[$0] == nil }) {
            lineup[openPosition] = player
        } else if let fallbackPosition = FieldPosition.autoAssignedPositions.first {
            lineup[fallbackPosition] = player
        }
        
        // Save this placement and copy it forward to later empty innings.
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }
    
    // MARK: - Fall Ball Generation
    // Generates all inning lineups using Fall Ball rules.
    func assignFallBallLineups() {
        // Nothing can be generated without eligible players.
        guard !activePlayers.isEmpty else { return }

        // Track play/bench counts so generated lineups can spread playing time.
        var playCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var benchCounts = Dictionary(uniqueKeysWithValues: activePlayers.map { ($0.id, 0) })
        var generatedLineups: [Int: [FieldPosition: Player]] = [:]
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

            if let pitcher = assignment[.pitcher] {
                generatedPitchers[inning] = pitcher.id
            }

            if let catcher = assignment[.catcher] {
                generatedCatchers[inning] = catcher.id
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

    // Builds one standard Fall Ball inning assignment.
    // Pitcher is selected from rated pitchers and rotated when possible; catcher stays manual.
    private func randomFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int], usedPitcherIDs: inout Set<UUID>) -> [FieldPosition: Player] {
        // Track used players so a player is not assigned to multiple positions in the same inning.
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        // Pitcher pool includes only players with a pitcher rating.
        let availablePitchers = eligiblePlayers.filter { $0.positionRatings[.pitcher] != nil }
        let pitcherCandidates = availablePitchers.filter { !usedPitcherIDs.contains($0.id) }
        let selectedPitcher = (pitcherCandidates.isEmpty ? availablePitchers : pitcherCandidates)
            .shuffled()
            .sorted { lhs, rhs in
                playCounts[lhs.id, default: 0] < playCounts[rhs.id, default: 0]
            }
            .first

        // Assign the selected pitcher and record that they have pitched.
        if let pitcher = selectedPitcher {
            assignments[.pitcher] = pitcher
            usedPlayerIDs.insert(pitcher.id)
            usedPitcherIDs.insert(pitcher.id)
            playCounts[pitcher.id, default: 0] += 1
        }

        // Standard Fall Ball keeps the manually selected catcher when available.
        if let catcher = eligiblePlayers.first(where: { $0.id == catcherID }), !usedPlayerIDs.contains(catcher.id) {
            assignments[.catcher] = catcher
            usedPlayerIDs.insert(catcher.id)
            playCounts[catcher.id, default: 0] += 1
        }

        // Fill remaining auto-assigned positions while favoring players with fewer plays.
        for position in FieldPosition.autoAssignedPositions.shuffled() {
            // Candidate must be unused this inning and rated for the position.
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

            // Assign the best candidate and increment their play count.
            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer
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
    private func randomYouthFallBallAssignment(playCounts: inout [UUID: Int], benchCounts: inout [UUID: Int]) -> [FieldPosition: Player] {
        // Track assignments and player usage for this one inning.
        var assignments: [FieldPosition: Player] = [:]
        var usedPlayerIDs = Set<UUID>()
        let eligiblePlayers = activePlayers

        // Shuffle positions so assignment order varies between innings.
        for position in FieldPosition.allCases.shuffled() {
            // Prefer players with fewer plays so time is distributed more evenly.
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

            // Assign the chosen player and increment their play count.
            if let selectedPlayer = candidates.first {
                assignments[position] = selectedPlayer
                usedPlayerIDs.insert(selectedPlayer.id)
                playCounts[selectedPlayer.id, default: 0] += 1
            }
        }

        updateBenchCounts(usedPlayerIDs: usedPlayerIDs, benchCounts: &benchCounts)
        return assignments
    }

    // Updates bench counts for players who did not receive a field assignment this inning.
    private func updateBenchCounts(usedPlayerIDs: Set<UUID>, benchCounts: inout [UUID: Int]) {
        for player in activePlayers where !usedPlayerIDs.contains(player.id) {
            benchCounts[player.id, default: 0] += 1
        }
    }

    // MARK: - Inning Selection and Persistence
    // Saves the current inning, switches to another inning, and loads its saved lineup.
    func selectInning(_ inning: Int) {
        // Capture edits before leaving the current inning.
        saveCurrentInningState()
        // Clamp the requested inning into the valid range.
        selectedInning = min(max(inning, 1), numberOfInnings)

        // If this inning has never been edited, seed it from the previous inning.
        if inningLineups[selectedInning] == nil, selectedInning > 1 {
            inningLineups[selectedInning] = inningLineups[selectedInning - 1] ?? lineup
            inningPitcherIDs[selectedInning] = inningPitcherIDs[selectedInning - 1]
            inningCatcherIDs[selectedInning] = inningCatcherIDs[selectedInning - 1]
        }

        // Load the selected inning's lineup and battery assignments into active state.
        lineup = inningLineups[selectedInning] ?? [:]
        pitcherID = inningPitcherIDs[selectedInning]
        catcherID = inningCatcherIDs[selectedInning]
        save()
    }

    // Stores the current lineup, pitcher, and catcher values under the selected inning.
    func saveCurrentInningState() {
        // Save the visible defensive assignments for this inning.
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

    // MARK: - Pitcher / Catcher Updates
    // Updates pitcher state and prevents the same player from also being catcher.
    func updatePitcher(_ playerID: UUID?) {
        // Store the new pitcher selection.
        pitcherID = playerID
        if catcherID == playerID { catcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    // Updates catcher state and prevents the same player from also being pitcher.
    func updateCatcher(_ playerID: UUID?) {
        // Store the new catcher selection.
        catcherID = playerID
        if pitcherID == playerID { pitcherID = nil }
        saveCurrentInningState()
        copyCurrentInningForwardIfNeeded()
        save()
    }

    // MARK: - Forward Fill Helpers
    // Copies the current inning forward only into later innings that are still empty.
    func copyCurrentInningForwardIfNeeded() {
        // There are no later innings to update from the final inning.
        guard selectedInning < numberOfInnings else { return }

        // Preserve already-edited future innings while seeding blank ones.
        for inning in (selectedInning + 1)...numberOfInnings {
            if inningLineups[inning] == nil || inningLineups[inning]?.isEmpty == true {
                inningLineups[inning] = lineup
                inningPitcherIDs[inning] = pitcherID
                inningCatcherIDs[inning] = catcherID
            }
        }
    }
}
