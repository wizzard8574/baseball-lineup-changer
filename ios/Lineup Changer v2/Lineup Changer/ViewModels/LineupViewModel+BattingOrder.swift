// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupViewModel+BattingOrder.swift
//
//
//
import Foundation
import SwiftUI

// MARK: - Batting Order
extension LineupViewModel {
    private var baseballMaximumLineupBatterCount: Int { 9 }
    var baseballUsesRosterBat: Bool { showOnlyNineBattersAndDH }
    var baseballUsesNineBatterAndDH: Bool { !showOnlyNineBattersAndDH }

    // MARK: - Batting Order Helpers
    // Ensures battingOrderIDs matches the current roster without losing existing order.
    func syncBattingOrder() {
        // Remove IDs for players that no longer exist.
        let existingIDs = Set(players.map { $0.id })
        battingOrderIDs.removeAll { !existingIDs.contains($0) }

        // Append any new players that are missing from the batting order.
        for player in players where !battingOrderIDs.contains(player.id) {
            battingOrderIDs.append(player.id)
        }
        syncDesignatedHitterSelection()
        save()
    }
    // Finds a player by ID.
    func player(for id: UUID) -> Player? {
        players.first { $0.id == id }
    }

    var baseballLineupEligiblePlayers: [Player] {
        baseballOrderedEligibleBatterPlayers()
    }

    var baseballDisplayedBatters: [Player] {
        if baseballUsesNineBatterAndDH {
            return Array(baseballLineupEligiblePlayers.prefix(baseballEffectiveLineupBatterCount))
        }

        return baseballLineupEligiblePlayers
    }

    var baseballDisplayedBattersForLineup: [Player] {
        guard baseballUsesNineBatterAndDH,
              let designatedHitterID,
              let designatedHitterForID,
              let designatedHitter = player(for: designatedHitterID),
              designatedHitterCandidates.contains(where: { $0.id == designatedHitterID }) else {
            return baseballDisplayedBatters
        }

        return baseballDisplayedBatters.map { batter in
            batter.id == designatedHitterForID ? designatedHitter : batter
        }
    }

    var baseballBenchBatters: [Player] {
        guard baseballUsesNineBatterAndDH else { return [] }
        return Array(baseballLineupEligiblePlayers.dropFirst(baseballEffectiveLineupBatterCount))
    }

    var designatedHitterCandidates: [Player] {
        baseballBenchBatters
    }

    var designatedHitterForCandidates: [Player] {
        baseballDisplayedBatters
    }

    func syncDesignatedHitterSelection() {
        guard baseballUsesNineBatterAndDH else { return }

        clampBaseballLineupBatterCount()

        let dhCandidateIDs = Set(designatedHitterCandidates.map(\.id))
        let dhForCandidateIDs = Set(designatedHitterForCandidates.map(\.id))

        if let designatedHitterID, !dhCandidateIDs.contains(designatedHitterID) {
            self.designatedHitterID = nil
        }

        if let designatedHitterForID, !dhForCandidateIDs.contains(designatedHitterForID) {
            self.designatedHitterForID = nil
        }

        syncBaseballFieldAssignmentsToLineupBattersIfNeeded()
    }

    func isBaseballFieldAssignablePlayer(_ playerID: UUID) -> Bool {
        guard baseballUsesNineBatterAndDH else {
            return activePlayers.contains { $0.id == playerID }
        }

        return baseballDisplayedBatters.contains { $0.id == playerID }
    }

    func syncBaseballFieldAssignmentsToLineupBattersIfNeeded() {
        guard baseballUsesNineBatterAndDH else { return }

        let lineupBatterIDs = Set(baseballDisplayedBatters.map(\.id))
        var didChange = false

        let filteredLineup = lineup.filter { _, playerID in
            lineupBatterIDs.contains(playerID)
        }
        if filteredLineup.count != lineup.count {
            lineup = filteredLineup
            didChange = true
        }

        if let pitcherID, !lineupBatterIDs.contains(pitcherID) {
            self.pitcherID = nil
            didChange = true
        }

        if let catcherID, !lineupBatterIDs.contains(catcherID) {
            self.catcherID = nil
            didChange = true
        }

        for inning in Array(inningLineups.keys) {
            let filteredInningLineup = inningLineups[inning]?.filter { _, playerID in
                lineupBatterIDs.contains(playerID)
            } ?? [:]

            if filteredInningLineup.count != inningLineups[inning]?.count {
                inningLineups[inning] = filteredInningLineup
                didChange = true
            }
        }

        let invalidPitcherInnings = inningPitcherIDs.compactMap { inning, playerID in
            lineupBatterIDs.contains(playerID) ? nil : inning
        }
        for inning in invalidPitcherInnings {
            inningPitcherIDs.removeValue(forKey: inning)
            didChange = true
        }

        let invalidCatcherInnings = inningCatcherIDs.compactMap { inning, playerID in
            lineupBatterIDs.contains(playerID) ? nil : inning
        }
        for inning in invalidCatcherInnings {
            inningCatcherIDs.removeValue(forKey: inning)
            didChange = true
        }

        if didChange {
            saveCurrentInningState()
        }
    }

    func moveBatter(playerID: UUID, toBattingOrderIndex destinationIndex: Int) {
        var orderedIDs = baseballOrderedEligibleBatterPlayers().map(\.id)
        guard let currentIndex = orderedIDs.firstIndex(of: playerID) else { return }

        let currentLineupCount = baseballEffectiveLineupBatterCount
        let wasInLineup = currentIndex < currentLineupCount
        if baseballUsesNineBatterAndDH && !wasInLineup && currentLineupCount >= baseballMaximumLineupBatterCount {
            baseballLineupLimitWarningText = "You can't add more than 9 to the lineup"
            return
        }

        orderedIDs.removeAll { $0 == playerID }
        let newLineupCount = baseballUsesNineBatterAndDH && !wasInLineup
            ? currentLineupCount + 1
            : currentLineupCount
        let maxLineupIndex = baseballUsesNineBatterAndDH
            ? max(newLineupCount - 1, 0)
            : orderedIDs.count
        let clampedIndex = min(max(destinationIndex, 0), min(maxLineupIndex, orderedIDs.count))
        orderedIDs.insert(playerID, at: clampedIndex)
        setBaseballLineupBatterCountIfNeeded(newLineupCount)
        baseballLineupLimitWarningText = nil
        saveBaseballEligibleBatterOrder(orderedIDs)
    }

    func moveBatterToBench(playerID: UUID) {
        var orderedIDs = baseballOrderedEligibleBatterPlayers().map(\.id)
        guard let currentIndex = orderedIDs.firstIndex(of: playerID) else { return }

        let currentLineupCount = baseballEffectiveLineupBatterCount
        let wasInLineup = currentIndex < currentLineupCount
        orderedIDs.removeAll { $0 == playerID }
        let newLineupCount = baseballUsesNineBatterAndDH && wasInLineup
            ? max(currentLineupCount - 1, 0)
            : currentLineupCount
        let benchStartIndex = baseballUsesNineBatterAndDH ? min(newLineupCount, orderedIDs.count) : orderedIDs.count
        orderedIDs.insert(playerID, at: benchStartIndex)
        setBaseballLineupBatterCountIfNeeded(newLineupCount)
        baseballLineupLimitWarningText = nil
        saveBaseballEligibleBatterOrder(orderedIDs)
    }

    func moveBatter(playerID: UUID, beforeBenchPlayerID destinationPlayerID: UUID) {
        var orderedIDs = baseballOrderedEligibleBatterPlayers().map(\.id)
        guard let currentIndex = orderedIDs.firstIndex(of: playerID),
              orderedIDs.contains(destinationPlayerID),
              playerID != destinationPlayerID else { return }

        let currentLineupCount = baseballEffectiveLineupBatterCount
        let wasInLineup = currentIndex < currentLineupCount
        orderedIDs.removeAll { $0 == playerID }
        let destinationIndex = orderedIDs.firstIndex(of: destinationPlayerID) ?? orderedIDs.count
        let newLineupCount = baseballUsesNineBatterAndDH && wasInLineup
            ? max(currentLineupCount - 1, 0)
            : currentLineupCount
        let benchStartIndex = baseballUsesNineBatterAndDH ? min(newLineupCount, orderedIDs.count) : destinationIndex
        orderedIDs.insert(playerID, at: max(destinationIndex, benchStartIndex))
        setBaseballLineupBatterCountIfNeeded(newLineupCount)
        baseballLineupLimitWarningText = nil
        saveBaseballEligibleBatterOrder(orderedIDs)
    }

    func forceReplaceBaseballBatter(atBattingOrderIndex index: Int, with playerID: UUID) -> Bool {
        guard baseballUsesNineBatterAndDH else {
            moveBatter(playerID: playerID, toBattingOrderIndex: index)
            return true
        }

        var orderedPlayers = baseballOrderedEligibleBatterPlayers()
        guard index >= 0,
              index < baseballEffectiveLineupBatterCount,
              orderedPlayers.indices.contains(index),
              let playerIndex = orderedPlayers.firstIndex(where: { $0.id == playerID }),
              playerIndex != index else { return false }

        orderedPlayers.swapAt(index, playerIndex)
        baseballLineupLimitWarningText = nil
        saveBaseballEligibleBatterOrder(orderedPlayers.map(\.id))
        return true
    }

    func replaceBaseballLineupBatter(with benchPlayerID: UUID, for lineupPlayerID: UUID) -> Bool {
        guard baseballUsesNineBatterAndDH else { return false }

        var orderedPlayers = baseballOrderedEligibleBatterPlayers()
        guard let lineupIndex = orderedPlayers.firstIndex(where: { $0.id == lineupPlayerID }),
              lineupIndex < baseballEffectiveLineupBatterCount,
              let benchIndex = orderedPlayers.firstIndex(where: { $0.id == benchPlayerID }),
              benchIndex >= baseballEffectiveLineupBatterCount else { return false }

        orderedPlayers.swapAt(lineupIndex, benchIndex)
        baseballLineupLimitWarningText = nil
        saveBaseballEligibleBatterOrder(orderedPlayers.map(\.id))
        return true
    }

    func clearBaseballLineupToBench() {
        guard baseballUsesNineBatterAndDH else { return }

        let sortedEligibleIDs = baseballLineupEligiblePlayers
            .sorted(by: baseballPlayerNumberSort)
            .map(\.id)

        baseballLineupBatterCount = 0
        designatedHitterID = nil
        designatedHitterForID = nil
        baseballLineupLimitWarningText = nil
        saveBaseballEligibleBatterOrder(sortedEligibleIDs)
    }

    private func baseballPlayerNumberSort(_ lhs: Player, _ rhs: Player) -> Bool {
        let lhsNumber = Int(lhs.number)
        let rhsNumber = Int(rhs.number)
        switch (lhsNumber, rhsNumber) {
        case let (l?, r?):
            return l < r
        case (nil, nil):
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        }
    }

    private func baseballOrderedEligibleBatterPlayers() -> [Player] {
        let eligiblePlayers = activePlayers
        let eligibleIDs = Set(eligiblePlayers.map(\.id))
        let playersByID = Dictionary(uniqueKeysWithValues: eligiblePlayers.map { ($0.id, $0) })
        let orderedPlayers = battingOrderIDs.compactMap { playerID -> Player? in
            guard eligibleIDs.contains(playerID) else { return nil }
            return playersByID[playerID]
        }
        let orderedIDs = Set(orderedPlayers.map(\.id))
        let missingPlayers = eligiblePlayers.filter { !orderedIDs.contains($0.id) }

        return orderedPlayers + missingPlayers
    }

    private func saveBaseballEligibleBatterOrder(_ eligibleOrder: [UUID]) {
        let eligibleIDSet = Set(activePlayers.map(\.id))
        let ineligibleIDs = battingOrderIDs.filter { !eligibleIDSet.contains($0) && player(for: $0) != nil }
        battingOrderIDs = eligibleOrder + ineligibleIDs
        clampBaseballLineupBatterCount()
        syncDesignatedHitterSelection()
        save()
    }

    private var baseballEffectiveLineupBatterCount: Int {
        let eligibleCount = baseballLineupEligiblePlayers.count
        guard baseballUsesNineBatterAndDH else { return eligibleCount }
        return min(max(baseballLineupBatterCount ?? min(baseballMaximumLineupBatterCount, eligibleCount), 0), baseballMaximumLineupBatterCount, eligibleCount)
    }

    private func setBaseballLineupBatterCountIfNeeded(_ count: Int) {
        guard baseballUsesNineBatterAndDH else { return }
        baseballLineupBatterCount = min(max(count, 0), baseballMaximumLineupBatterCount, baseballLineupEligiblePlayers.count)
    }

    private func clampBaseballLineupBatterCount() {
        guard baseballUsesNineBatterAndDH, let baseballLineupBatterCount else { return }
        let clampedCount = min(max(baseballLineupBatterCount, 0), baseballMaximumLineupBatterCount, baseballLineupEligiblePlayers.count)
        if clampedCount != baseballLineupBatterCount {
            self.baseballLineupBatterCount = clampedCount
        }
    }

    // Reorders batting order IDs after the user drags rows in the lineup screen.
    func moveBatters(from source: IndexSet, to destination: Int) {
        // Sync first so the move operation acts on a valid, current batting order.
        syncBattingOrder()
        battingOrderIDs.move(fromOffsets: source, toOffset: destination)
        syncDesignatedHitterSelection()
        save()
    }

    // MARK: - GameChanger Batting Order Sorting
    // Supported GameChanger statistics that can drive automatic batting-order sorting.
    enum GameChangerSortStat {
        case avg
        case obp
        case ops
        case slg
        case hits
        case rbi
        case runs
        case walks
        case strikeouts
    }

    // Sorts the batting order by one imported GameChanger statistic.
    // Players with valid imported stats are placed first, sorted highest-to-lowest by default.
    // Players without that stat keep their existing relative order after the stat-backed players.
    func sortBattingOrderByGameChangerStat(_ stat: GameChangerSortStat, descending: Bool = true) {
        // Make sure the batting order contains only current players before sorting.
        syncBattingOrder()

        // Keep the current order available as a stable fallback/tie-breaker.
        let currentOrder = battingOrderIDs
        let currentOrderIndex = Dictionary(uniqueKeysWithValues: currentOrder.enumerated().map { ($0.element, $0.offset) })

        // Sort player IDs instead of Player values so the lineup tab continues using the same source of truth.
        battingOrderIDs = currentOrder.sorted { lhsID, rhsID in
            guard let lhsPlayer = player(for: lhsID), let rhsPlayer = player(for: rhsID) else {
                return (currentOrderIndex[lhsID] ?? 0) < (currentOrderIndex[rhsID] ?? 0)
            }

            let lhsValue = gameChangerSortValue(for: lhsPlayer, stat: stat)
            let rhsValue = gameChangerSortValue(for: rhsPlayer, stat: stat)

            switch (lhsValue, rhsValue) {
            case let (lhs?, rhs?):
                // When both players have the stat, sort by the stat value and preserve current order for ties.
                if lhs == rhs {
                    return (currentOrderIndex[lhsID] ?? 0) < (currentOrderIndex[rhsID] ?? 0)
                }
                return descending ? lhs > rhs : lhs < rhs

            case (_?, nil):
                // Players with a valid stat sort ahead of players missing the stat.
                return true

            case (nil, _?):
                // Players missing the selected stat sort behind players with data.
                return false

            case (nil, nil):
                // If neither player has the stat, keep their existing batting-order relationship.
                return (currentOrderIndex[lhsID] ?? 0) < (currentOrderIndex[rhsID] ?? 0)
            }
        }

        // Persist the new batting order.
        syncDesignatedHitterSelection()
        save()
    }

    // Converts a player's selected GameChanger stat into a sortable number.
    private func gameChangerSortValue(for player: Player, stat: GameChangerSortStat) -> Double? {
        // Players without imported GameChanger stats cannot be sorted by stat value.
        guard let stats = player.gameChangerStats else { return nil }

        // Pick the requested stat string from the imported stat bundle.
        let rawValue: String
        switch stat {
        case .avg:
            rawValue = stats.avg
        case .obp:
            rawValue = stats.obp
        case .ops:
            rawValue = stats.ops
        case .slg:
            rawValue = stats.slg
        case .hits:
            rawValue = stats.hits
        case .rbi:
            rawValue = stats.rbi
        case .runs:
            rawValue = stats.runs
        case .walks:
            rawValue = stats.walks
        case .strikeouts:
            rawValue = stats.strikeouts
        }

        // GameChanger values may contain formatting characters, so keep digits, decimal points, and minus signs only.
        let cleanedValue = rawValue.filter { character in
            character.isNumber || character == "." || character == "-"
        }

        // Empty, dash-only, or nonnumeric values are treated as missing.
        return Double(cleanedValue)
    }
}
