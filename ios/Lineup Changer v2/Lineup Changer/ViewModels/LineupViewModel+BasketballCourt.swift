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
        var remainingPlayers = basketballLineupPlayers
        var periodLineup: [BasketballPosition: UUID] = [:]

        for position in BasketballPosition.allCases {
            let ratedPlayers = remainingPlayers.filter { $0.basketballPositionRatings[position] != nil }

            guard let bestPlayer = ratedPlayers.min(by: { lhs, rhs in
                basketballCourtSortsBefore(lhs, rhs, for: position)
            }) else { continue }

            periodLineup[position] = bestPlayer.id
            remainingPlayers.removeAll { $0.id == bestPlayer.id }
        }

        basketballCourtLineupIDsByPeriod[period] = periodLineup
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
