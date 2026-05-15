// Created by Rich Morris on 5/5/26.
// Lineup Changer
// TeamSnapshot.swift
//
//
//
import Foundation

// MARK: - Team Snapshot Model
// Team-specific saved state used when switching between team slots.

struct TeamSnapshot: Codable {
    // Team roster and staff data.
    var players: [Player]
    var coaches: [Coach]?
    // Team field assignment state.
    var pitcherID: UUID?
    var catcherID: UUID?
    var lineup: [FieldPosition: Player]
    var lineupIDs: [FieldPosition: UUID]
    // Team inning-specific lineup storage.
    var selectedInning: Int
    var inningLineups: [Int: [FieldPosition: Player]]
    var inningLineupIDs: [Int: [FieldPosition: UUID]]
    var inningPitcherIDs: [Int: UUID]
    var inningCatcherIDs: [Int: UUID]
    // Team batting order and DH state.
    var battingOrderIDs: [UUID]
    var baseballLineupBatterCount: Int?
    var designatedHitterID: UUID?
    var designatedHitterForID: UUID?
    var basketballUsesExplicitStartingLineup: Bool?
    var basketballStartingLineupIDs: [BasketballPosition: UUID]?
    var basketballCourtLineupIDsByPeriod: [Int: [BasketballPosition: UUID]]?
    // Team notes and selected sport.
    var preGameNotes: String?
    var postGameNotes: String?
    var coachNotes: String?
    var selectedSport: SportType?

    init(players: [Player],
         coaches: [Coach]? = [],
         pitcherID: UUID? = nil,
         catcherID: UUID? = nil,
         lineup: [FieldPosition: Player] = [:],
         lineupIDs: [FieldPosition: UUID] = [:],
         selectedInning: Int = 1,
         inningLineups: [Int: [FieldPosition: Player]] = [:],
         inningLineupIDs: [Int: [FieldPosition: UUID]] = [:],
         inningPitcherIDs: [Int: UUID] = [:],
         inningCatcherIDs: [Int: UUID] = [:],
         battingOrderIDs: [UUID] = [],
         baseballLineupBatterCount: Int? = nil,
         designatedHitterID: UUID? = nil,
         designatedHitterForID: UUID? = nil,
         basketballUsesExplicitStartingLineup: Bool? = nil,
         basketballStartingLineupIDs: [BasketballPosition: UUID]? = nil,
         basketballCourtLineupIDsByPeriod: [Int: [BasketballPosition: UUID]]? = nil,
         preGameNotes: String? = "",
         postGameNotes: String? = "",
         coachNotes: String? = "",
         selectedSport: SportType? = .baseballSoftball) {
        self.players = players
        self.coaches = coaches
        self.pitcherID = pitcherID
        self.catcherID = catcherID
        self.lineup = lineup
        self.lineupIDs = lineupIDs
        self.selectedInning = selectedInning
        self.inningLineups = inningLineups
        self.inningLineupIDs = inningLineupIDs
        self.inningPitcherIDs = inningPitcherIDs
        self.inningCatcherIDs = inningCatcherIDs
        self.battingOrderIDs = battingOrderIDs
        self.baseballLineupBatterCount = baseballLineupBatterCount
        self.designatedHitterID = designatedHitterID
        self.designatedHitterForID = designatedHitterForID
        self.basketballUsesExplicitStartingLineup = basketballUsesExplicitStartingLineup
        self.basketballStartingLineupIDs = basketballStartingLineupIDs
        self.basketballCourtLineupIDsByPeriod = basketballCourtLineupIDsByPeriod
        self.preGameNotes = preGameNotes
        self.postGameNotes = postGameNotes
        self.coachNotes = coachNotes
        self.selectedSport = selectedSport
    }
}
