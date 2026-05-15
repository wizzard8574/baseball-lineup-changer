// Created by Rich Morris on 5/13/26.
// Lineup Changer
// LineupViewModel+BasketballLineup.swift
//
//
//
import Foundation

// MARK: - Basketball Lineup
extension LineupViewModel {
    var basketballLineupPlayers: [Player] {
        basketballOrderedEligiblePlayers()
    }

    var basketballStartingLineupPlayers: [Player] {
        if basketballUsesExplicitStartingLineup {
            return BasketballPosition.allCases.compactMap { position in
                basketballStartingLineupIDs[position].flatMap { player(for: $0) }
            }
        }

        return Array(basketballLineupPlayers.prefix(BasketballPosition.allCases.count))
    }

    var basketballBenchPlayers: [Player] {
        if basketballUsesExplicitStartingLineup {
            let starterIDs = Set(basketballStartingLineupIDs.values)
            return basketballLineupPlayers.filter { !starterIDs.contains($0.id) }
        }

        return Array(basketballLineupPlayers.dropFirst(BasketballPosition.allCases.count))
    }

    func basketballStartingPlayer(for position: BasketballPosition) -> Player? {
        if basketballUsesExplicitStartingLineup {
            guard let playerID = basketballStartingLineupIDs[position] else { return nil }
            return player(for: playerID)
        }

        guard let index = BasketballPosition.allCases.firstIndex(of: position) else { return nil }
        let starters = basketballStartingLineupPlayers
        return starters.indices.contains(index) ? starters[index] : nil
    }

    func basketballStartingPosition(for playerID: UUID) -> BasketballPosition? {
        if basketballUsesExplicitStartingLineup {
            return basketballStartingLineupIDs.first { $0.value == playerID }?.key
        }

        guard let index = basketballStartingLineupPlayers.firstIndex(where: { $0.id == playerID }),
              BasketballPosition.allCases.indices.contains(index) else { return nil }

        return BasketballPosition.allCases[index]
    }

    func basketballBenchPlayersRated(for position: BasketballPosition) -> [Player] {
        basketballBenchPlayers
            .filter { $0.basketballPositionRatings[position] != nil }
            .sorted { basketballLineupSortsBefore($0, $1, for: position) }
    }

    func syncBasketballLineup(autoAssignIfDefaultOrder: Bool = false) {
        let eligiblePlayers = basketballEligiblePlayers()
        let eligibleIDs = Set(eligiblePlayers.map(\.id))
        let defaultEligibleOrder = eligiblePlayers.map(\.id)
        let currentEligibleOrder = battingOrderIDs.filter { eligibleIDs.contains($0) }
        let missingEligibleIDs = defaultEligibleOrder.filter { !currentEligibleOrder.contains($0) }
        let syncedEligibleOrder = currentEligibleOrder + missingEligibleIDs
        syncBasketballExplicitStartingLineupWithRoster(eligibleIDs: eligibleIDs)

        let shouldAutoAssign = autoAssignIfDefaultOrder
            && !basketballUsesExplicitStartingLineup
            && syncedEligibleOrder == defaultEligibleOrder
            && eligiblePlayers.contains { !$0.basketballPositionRatings.isEmpty }

        if shouldAutoAssign {
            assignBestBasketballLineup()
            return
        }

        let ineligibleIDs = battingOrderIDs.filter { !eligibleIDs.contains($0) && player(for: $0) != nil }
        battingOrderIDs = syncedEligibleOrder + ineligibleIDs
        save()
    }

    func assignBestBasketballLineup() {
        var remainingPlayers = basketballEligiblePlayers()
        var starterIDs: [UUID] = []

        for position in BasketballPosition.allCases {
            guard let bestPlayer = remainingPlayers.min(by: { lhs, rhs in
                basketballLineupSortsBefore(lhs, rhs, for: position)
            }) else { break }

            starterIDs.append(bestPlayer.id)
            remainingPlayers.removeAll { $0.id == bestPlayer.id }
        }

        let starterIDSet = Set(starterIDs)
        let currentEligibleOrder = basketballOrderedEligiblePlayers().map(\.id)
        let benchIDs = currentEligibleOrder.filter { !starterIDSet.contains($0) }
        let eligibleIDs = Set((starterIDs + benchIDs))
        let ineligibleIDs = battingOrderIDs.filter { !eligibleIDs.contains($0) && player(for: $0) != nil }

        basketballUsesExplicitStartingLineup = true
        basketballStartingLineupIDs = Dictionary(uniqueKeysWithValues: zip(BasketballPosition.allCases, starterIDs))
        battingOrderIDs = starterIDs + benchIDs + ineligibleIDs
        save()
    }

    func clearBasketballLineupToBench() {
        basketballUsesExplicitStartingLineup = true
        basketballStartingLineupIDs = [:]
        save()
    }

    func moveBasketballLineupPlayer(playerID: UUID, toStartingIndex destinationIndex: Int) {
        if basketballUsesExplicitStartingLineup,
           BasketballPosition.allCases.indices.contains(destinationIndex) {
            _ = forceReplaceBasketballStarter(at: BasketballPosition.allCases[destinationIndex], with: playerID)
            return
        }

        var orderedIDs = basketballOrderedEligiblePlayers().map(\.id)
        guard orderedIDs.contains(playerID) else { return }

        orderedIDs.removeAll { $0 == playerID }
        let clampedIndex = min(max(destinationIndex, 0), min(BasketballPosition.allCases.count - 1, orderedIDs.count))
        orderedIDs.insert(playerID, at: clampedIndex)
        saveBasketballEligibleOrder(orderedIDs)
    }

    func moveBasketballLineupPlayerToBench(playerID: UUID) {
        if basketballUsesExplicitStartingLineup {
            basketballStartingLineupIDs = basketballStartingLineupIDs.filter { $0.value != playerID }
            save()
            return
        }

        var orderedIDs = basketballOrderedEligiblePlayers().map(\.id)
        guard orderedIDs.contains(playerID) else { return }

        orderedIDs.removeAll { $0 == playerID }
        let benchStartIndex = min(BasketballPosition.allCases.count, orderedIDs.count)
        orderedIDs.insert(playerID, at: benchStartIndex)
        saveBasketballEligibleOrder(orderedIDs)
    }

    func moveBasketballLineupPlayer(playerID: UUID, beforePlayerID destinationPlayerID: UUID) {
        var orderedIDs = basketballOrderedEligiblePlayers().map(\.id)
        guard orderedIDs.contains(playerID), orderedIDs.contains(destinationPlayerID), playerID != destinationPlayerID else { return }

        orderedIDs.removeAll { $0 == playerID }
        let destinationIndex = orderedIDs.firstIndex(of: destinationPlayerID) ?? orderedIDs.count
        orderedIDs.insert(playerID, at: destinationIndex)
        saveBasketballEligibleOrder(orderedIDs)
    }

    func replaceBasketballStarter(at position: BasketballPosition, with benchPlayerID: UUID) {
        if basketballUsesExplicitStartingLineup {
            _ = forceReplaceBasketballStarter(at: position, with: benchPlayerID)
            return
        }

        guard let positionIndex = BasketballPosition.allCases.firstIndex(of: position) else { return }

        var orderedIDs = basketballOrderedEligiblePlayers().map(\.id)
        guard orderedIDs.indices.contains(positionIndex),
              let benchIndex = orderedIDs.firstIndex(of: benchPlayerID),
              benchIndex >= BasketballPosition.allCases.count,
              let benchPlayer = player(for: benchPlayerID),
              benchPlayer.basketballPositionRatings[position] != nil else { return }

        orderedIDs.swapAt(positionIndex, benchIndex)
        saveBasketballEligibleOrder(orderedIDs)
    }

    func forceReplaceBasketballStarter(at position: BasketballPosition, with playerID: UUID) -> (incoming: Player, replaced: Player?, incomingIsRated: Bool)? {
        if basketballUsesExplicitStartingLineup {
            let eligibleIDs = Set(basketballEligiblePlayers().map(\.id))
            guard eligibleIDs.contains(playerID),
                  let incomingPlayer = player(for: playerID) else { return nil }

            let replacedPlayer = basketballStartingLineupIDs[position].flatMap { player(for: $0) }
            guard replacedPlayer?.id != playerID else { return nil }

            var startingIDs = basketballStartingLineupIDs
            for startingPosition in BasketballPosition.allCases where startingIDs[startingPosition] == playerID {
                startingIDs[startingPosition] = nil
            }
            startingIDs[position] = playerID

            basketballStartingLineupIDs = startingIDs
            save()

            return (incomingPlayer, replacedPlayer, incomingPlayer.basketballPositionRatings[position] != nil)
        }

        guard let positionIndex = BasketballPosition.allCases.firstIndex(of: position) else { return nil }

        var orderedPlayers = basketballOrderedEligiblePlayers()
        guard orderedPlayers.indices.contains(positionIndex),
              let playerIndex = orderedPlayers.firstIndex(where: { $0.id == playerID }),
              playerIndex != positionIndex else { return nil }

        let incomingPlayer = orderedPlayers[playerIndex]
        let replacedPlayer = orderedPlayers[positionIndex]
        let incomingIsRated = incomingPlayer.basketballPositionRatings[position] != nil

        orderedPlayers.swapAt(positionIndex, playerIndex)
        saveBasketballEligibleOrder(orderedPlayers.map(\.id))

        return (incomingPlayer, replacedPlayer, incomingIsRated)
    }

    func replaceBasketballStarterWithBestBenchPlayer(at position: BasketballPosition) -> Player? {
        guard let replacement = basketballBenchPlayersRated(for: position).first else { return nil }
        replaceBasketballStarter(at: position, with: replacement.id)
        return replacement
    }

    private func basketballEligiblePlayers() -> [Player] {
        activePlayers
    }

    private func basketballOrderedEligiblePlayers() -> [Player] {
        let eligiblePlayers = basketballEligiblePlayers()
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

    private func syncBasketballExplicitStartingLineupWithRoster(eligibleIDs: Set<UUID>) {
        guard basketballUsesExplicitStartingLineup else { return }

        let filteredStartingIDs = basketballStartingLineupIDs.filter { eligibleIDs.contains($0.value) }
        if filteredStartingIDs.count != basketballStartingLineupIDs.count {
            basketballStartingLineupIDs = filteredStartingIDs
        }
    }

    private func basketballLineupSortsBefore(_ lhs: Player, _ rhs: Player, for position: BasketballPosition) -> Bool {
        let lhsRating = lhs.basketballPositionRatings[position] ?? Int.max
        let rhsRating = rhs.basketballPositionRatings[position] ?? Int.max

        if lhsRating != rhsRating {
            return lhsRating < rhsRating
        }

        return basketballLineupTieBreaksBefore(lhs, rhs)
    }

    private func basketballLineupTieBreaksBefore(_ lhs: Player, _ rhs: Player) -> Bool {
        let lhsNumber = Int(lhs.number)
        let rhsNumber = Int(rhs.number)

        switch (lhsNumber, rhsNumber) {
        case let (l?, r?) where l != r:
            return l < r
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func saveBasketballEligibleOrder(_ eligibleOrder: [UUID]) {
        let eligibleIDSet = Set(basketballEligiblePlayers().map(\.id))
        let ineligibleIDs = battingOrderIDs.filter { !eligibleIDSet.contains($0) && player(for: $0) != nil }
        battingOrderIDs = eligibleOrder + ineligibleIDs
        save()
    }
}
