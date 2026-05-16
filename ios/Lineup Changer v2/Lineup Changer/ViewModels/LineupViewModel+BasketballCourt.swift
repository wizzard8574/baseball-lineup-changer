// Created by Rich Morris on 5/15/26.
// Lineup Changer
// LineupViewModel+BasketballCourt.swift
//
//
//
import Foundation

// MARK: - Basketball Court
extension LineupViewModel {
    func basketballCourtLineupIDs(for period: Int) -> [BasketballPosition: UUID] {
        if let periodLineup = basketballCourtLineupIDsByPeriod[period] {
            return periodLineup
        }

        return defaultBasketballCourtLineupIDs()
    }

    func basketballCourtPlayer(for position: BasketballPosition, period: Int) -> Player? {
        basketballCourtLineupIDs(for: period)[position].flatMap { player(for: $0) }
    }

    func basketballCourtLineup(for period: Int) -> [BasketballPosition: Player] {
        Dictionary(uniqueKeysWithValues: BasketballPosition.allCases.compactMap { position in
            guard let player = basketballCourtPlayer(for: position, period: period) else { return nil }
            return (position, player)
        })
    }

    func basketballCourtBenchPlayers(for period: Int) -> [Player] {
        let assignedIDs = Set(basketballCourtLineupIDs(for: period).values)
        return basketballLineupPlayers.filter { !assignedIDs.contains($0.id) }
    }

    func updateBasketballCourtPosition(_ position: BasketballPosition, playerID: UUID?, period: Int) {
        var periodLineup = basketballCourtLineupIDs(for: period)

        periodLineup = periodLineup.filter { assignmentPosition, assignedPlayerID in
            assignmentPosition == position || assignedPlayerID != playerID
        }

        periodLineup[position] = playerID
        basketballCourtLineupIDsByPeriod[period] = periodLineup
        save()
    }

    func autoFillBasketballCourtPositions(for period: Int) {
        if usesYouthQuarterPlayedAutoFill {
            autoFillBasketballCourtPositionsForRequiredQuarters()
            return
        }

        var remainingPlayers = basketballLineupPlayers
        var periodLineup: [BasketballPosition: UUID] = [:]

        var unfilledPositions = BasketballPosition.allCases

        while let position = nextBasketballCourtPositionToFill(from: unfilledPositions, players: remainingPlayers) {
            let ratedPlayers = remainingPlayers.filter { $0.basketballPositionRatings[position] != nil }
            let candidatePlayers = ratedPlayers.isEmpty
                ? remainingPlayers.filter { !$0.basketballPositionRatings.isEmpty }
                : ratedPlayers

            guard let bestPlayer = candidatePlayers.min(by: { lhs, rhs in
                basketballCourtSortsBefore(lhs, rhs, for: position)
            }) else {
                unfilledPositions.removeAll { $0 == position }
                continue
            }

            periodLineup[position] = bestPlayer.id
            remainingPlayers.removeAll { $0.id == bestPlayer.id }
            unfilledPositions.removeAll { $0 == position }
        }

        basketballCourtLineupIDsByPeriod[period] = periodLineup
        save()
    }

    func autoFillBasketballCourtPositionsForRequiredQuarters() {
        let eligiblePlayers = basketballLineupPlayers.filter { !$0.basketballPositionRatings.isEmpty }
        guard !eligiblePlayers.isEmpty else {
            clearAllBasketballCourtLineups()
            return
        }

        let periodCount = BasketballPeriodFormat.quarters.periodCount
        let requiredQuarters = min(max(basketballRequiredQuartersPlayed, 1), periodCount)
        let requiredQuarterTargets = basketballRequiredQuarterTargets(
            playerCount: eligiblePlayers.count,
            requiredQuarters: requiredQuarters,
            periodCount: periodCount
        )
        var playCounts = Dictionary(uniqueKeysWithValues: eligiblePlayers.map { ($0.id, 0) })
        var generatedLineups: [Int: [BasketballPosition: UUID]] = [:]

        for period in 1...periodCount {
            var usedPlayerIDs = Set<UUID>()
            var periodLineup: [BasketballPosition: UUID] = [:]
            var requiredPlacementsRemaining = requiredQuarterTargets[period - 1]

            var unfilledPositions = BasketballPosition.allCases

            while let position = nextBasketballCourtPositionToFill(
                from: unfilledPositions,
                players: eligiblePlayers,
                usedPlayerIDs: usedPlayerIDs
            ) {
                guard let player = bestYouthQuarterPlayer(
                    for: position,
                    from: eligiblePlayers,
                    usedPlayerIDs: usedPlayerIDs,
                    playCounts: playCounts,
                    requiredQuarters: requiredQuarters,
                    requiredPlacementsRemaining: requiredPlacementsRemaining
                ) else {
                    unfilledPositions.removeAll { $0 == position }
                    continue
                }

                let wasBelowRequiredQuarters = (playCounts[player.id] ?? 0) < requiredQuarters
                periodLineup[position] = player.id
                usedPlayerIDs.insert(player.id)
                playCounts[player.id, default: 0] += 1
                if wasBelowRequiredQuarters {
                    requiredPlacementsRemaining = max(0, requiredPlacementsRemaining - 1)
                }
                unfilledPositions.removeAll { $0 == position }
            }

            generatedLineups[period] = periodLineup
        }

        basketballCourtLineupIDsByPeriod = generatedLineups
        save()
    }

    func useBasketballCourtLineupForAllPeriods(from period: Int) {
        let sourceLineup = basketballCourtLineupIDs(for: period)
        basketballCourtLineupIDsByPeriod = Dictionary(
            uniqueKeysWithValues: (1...basketballPeriodFormat.periodCount).map { ($0, sourceLineup) }
        )
        save()
    }

    func clearBasketballCourtLineup(for period: Int) {
        basketballCourtLineupIDsByPeriod[period] = [:]
        save()
    }

    func clearAllBasketballCourtLineups() {
        basketballCourtLineupIDsByPeriod = Dictionary(
            uniqueKeysWithValues: (1...basketballPeriodFormat.periodCount).map { ($0, [:]) }
        )
        save()
    }

    func syncBasketballCourtLineupsWithRoster() {
        let eligibleIDs = Set(basketballLineupPlayers.map(\.id))
        let filteredLineups = basketballCourtLineupIDsByPeriod.mapValues { lineup in
            lineup.filter { eligibleIDs.contains($0.value) }
        }

        if filteredLineups != basketballCourtLineupIDsByPeriod {
            basketballCourtLineupIDsByPeriod = filteredLineups
        }
    }

    private func defaultBasketballCourtLineupIDs() -> [BasketballPosition: UUID] {
        Dictionary(uniqueKeysWithValues: BasketballPosition.allCases.compactMap { position in
            guard let player = basketballStartingPlayer(for: position) else { return nil }
            return (position, player.id)
        })
    }

    private var usesYouthQuarterPlayedAutoFill: Bool {
        basketballYouthEnabled
        && basketballQuartersPlayedEnabled
        && basketballPeriodFormat == .quarters
    }

    private func nextBasketballCourtPositionToFill(
        from positions: [BasketballPosition],
        players: [Player],
        usedPlayerIDs: Set<UUID> = []
    ) -> BasketballPosition? {
        positions.min { lhs, rhs in
            let lhsCount = basketballCourtRatedCandidateCount(for: lhs, players: players, usedPlayerIDs: usedPlayerIDs)
            let rhsCount = basketballCourtRatedCandidateCount(for: rhs, players: players, usedPlayerIDs: usedPlayerIDs)
            let lhsPriority = lhsCount == 0 ? Int.max : lhsCount
            let rhsPriority = rhsCount == 0 ? Int.max : rhsCount

            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }

            return basketballCourtPositionIndex(lhs) < basketballCourtPositionIndex(rhs)
        }
    }

    private func basketballCourtRatedCandidateCount(
        for position: BasketballPosition,
        players: [Player],
        usedPlayerIDs: Set<UUID>
    ) -> Int {
        players.filter { player in
            !usedPlayerIDs.contains(player.id)
            && player.basketballPositionRatings[position] != nil
        }.count
    }

    private func basketballCourtPositionIndex(_ position: BasketballPosition) -> Int {
        BasketballPosition.allCases.firstIndex(of: position) ?? Int.max
    }

    private func basketballRequiredQuarterTargets(
        playerCount: Int,
        requiredQuarters: Int,
        periodCount: Int
    ) -> [Int] {
        let availableSlots = periodCount * BasketballPosition.allCases.count
        let requiredSlots = min(playerCount * requiredQuarters, availableSlots)
        let baseRequiredSlots = requiredSlots / periodCount
        let extraRequiredSlots = requiredSlots % periodCount

        return (0..<periodCount).map { index in
            baseRequiredSlots + (index < extraRequiredSlots ? 1 : 0)
        }
    }

    private func bestYouthQuarterPlayer(
        for position: BasketballPosition,
        from players: [Player],
        usedPlayerIDs: Set<UUID>,
        playCounts: [UUID: Int],
        requiredQuarters: Int,
        requiredPlacementsRemaining: Int
    ) -> Player? {
        let availablePlayers = players.filter { player in
            !usedPlayerIDs.contains(player.id)
            && player.basketballPositionRatings[position] != nil
        }
        let candidatePlayers = availablePlayers.isEmpty
            ? players.filter { player in
                !usedPlayerIDs.contains(player.id)
                && !player.basketballPositionRatings.isEmpty
            }
            : availablePlayers

        let playersNeedingRequiredQuarters = candidatePlayers.filter {
            (playCounts[$0.id] ?? 0) < requiredQuarters
        }
        let isPrioritizingRequiredPlayers = requiredPlacementsRemaining > 0 && !playersNeedingRequiredQuarters.isEmpty
        let prioritizedPlayers = isPrioritizingRequiredPlayers
            ? playersNeedingRequiredQuarters
            : candidatePlayers

        return prioritizedPlayers.min { lhs, rhs in
            let lhsCount = playCounts[lhs.id] ?? 0
            let rhsCount = playCounts[rhs.id] ?? 0

            if lhsCount != rhsCount && isPrioritizingRequiredPlayers {
                return lhsCount < rhsCount
            }

            return basketballCourtSortsBefore(lhs, rhs, for: position)
        }
    }

    private func basketballCourtSortsBefore(_ lhs: Player, _ rhs: Player, for position: BasketballPosition) -> Bool {
        let lhsRating = lhs.basketballPositionRatings[position] ?? Int.max
        let rhsRating = rhs.basketballPositionRatings[position] ?? Int.max

        if lhsRating != rhsRating {
            return lhsRating < rhsRating
        }

        return basketballCourtTieBreaksBefore(lhs, rhs)
    }

    private func basketballCourtTieBreaksBefore(_ lhs: Player, _ rhs: Player) -> Bool {
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
}
