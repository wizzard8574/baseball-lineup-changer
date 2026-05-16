// Created by Rich Morris on 5/5/26.
// Lineup Changer
// AppState.swift
//
//
//
import Foundation

// MARK: - App State Model
// Full persisted app state saved to UserDefaults.
// Includes global settings plus current/team-specific data for compatibility with older saves.

struct AppState: Codable {
    // Current team roster and staff data.
    var players: [Player]
    var coaches: [Coach]
    // Current defensive assignment state.
    var pitcherID: UUID?
    var catcherID: UUID?
    var lineup: [FieldPosition: Player]
    var lineupIDs: [FieldPosition: UUID]
    // Inning-specific lineup storage.
    var selectedInning: Int
    var inningLineups: [Int: [FieldPosition: Player]]
    var inningLineupIDs: [Int: [FieldPosition: UUID]]
    var inningPitcherIDs: [Int: UUID]
    var inningCatcherIDs: [Int: UUID]
    // Global display settings.
    var showRatingsOnField: Bool
    var showAssignedLineupTable: Bool
    var showFullNameAndNumber: Bool
    var showBenchOnField: Bool
    var showRatingsOnCourt: Bool?
    var showAssignedBasketballLineup: Bool?
    var showBasketballBenchOnCourt: Bool?
    var showFullNameAndNumberInBasketball: Bool?
    var basketballPeriodFormat: BasketballPeriodFormat?
    var basketballYouthEnabled: Bool?
    var basketballQuartersPlayedEnabled: Bool?
    var basketballRequiredQuartersPlayed: Int?
    var showOnlyNineBattersAndDH: Bool
    var showSlowSpeedBattingWarnings: Bool
    // Game format and lineup generation settings.
    var fallBallEnabled: Bool?
    var fallBallYouthEnabled: Bool?
    var fallBallRunRuleEnabled: Bool?
    // Batting order and designated hitter state.
    var battingOrderIDs: [UUID]
    var baseballLineupBatterCount: Int?
    var designatedHitterID: UUID?
    var designatedHitterForID: UUID?
    var basketballUsesExplicitStartingLineup: Bool?
    var basketballStartingLineupIDs: [BasketballPosition: UUID]?
    var basketballCourtLineupIDsByPeriod: [Int: [BasketballPosition: UUID]]?
    // Notes and selected sport.
    var preGameNotes: String?
    var postGameNotes: String?
    var coachNotes: String?
    var selectedSport: SportType?
    // Multi-team persistence support.
    var selectedTeamIndex: Int?
    var teamNames: [String]?
    var teamSnapshots: [TeamSnapshot]
    var sportTeamStates: [SportType: SportTeamState]

    init(players: [Player],
         coaches: [Coach],
         pitcherID: UUID?,
         catcherID: UUID?,
         lineup: [FieldPosition: Player],
         lineupIDs: [FieldPosition: UUID],
         selectedInning: Int,
         inningLineups: [Int: [FieldPosition: Player]],
         inningLineupIDs: [Int: [FieldPosition: UUID]],
         inningPitcherIDs: [Int: UUID],
         inningCatcherIDs: [Int: UUID],
         showRatingsOnField: Bool,
         showAssignedLineupTable: Bool,
         showFullNameAndNumber: Bool,
         showBenchOnField: Bool,
         showRatingsOnCourt: Bool?,
         showAssignedBasketballLineup: Bool?,
         showBasketballBenchOnCourt: Bool?,
         showFullNameAndNumberInBasketball: Bool?,
         basketballPeriodFormat: BasketballPeriodFormat?,
         basketballYouthEnabled: Bool?,
         basketballQuartersPlayedEnabled: Bool?,
         basketballRequiredQuartersPlayed: Int?,
         showOnlyNineBattersAndDH: Bool,
         showSlowSpeedBattingWarnings: Bool,
         fallBallEnabled: Bool?,
         fallBallYouthEnabled: Bool?,
         fallBallRunRuleEnabled: Bool?,
         battingOrderIDs: [UUID],
         baseballLineupBatterCount: Int?,
         designatedHitterID: UUID?,
         designatedHitterForID: UUID?,
         basketballUsesExplicitStartingLineup: Bool?,
         basketballStartingLineupIDs: [BasketballPosition: UUID]?,
         basketballCourtLineupIDsByPeriod: [Int: [BasketballPosition: UUID]]?,
         preGameNotes: String?,
         postGameNotes: String?,
         coachNotes: String?,
         selectedSport: SportType?,
         selectedTeamIndex: Int?,
         teamNames: [String]?,
         teamSnapshots: [TeamSnapshot],
         sportTeamStates: [SportType: SportTeamState]) {
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
        self.showRatingsOnField = showRatingsOnField
        self.showAssignedLineupTable = showAssignedLineupTable
        self.showFullNameAndNumber = showFullNameAndNumber
        self.showBenchOnField = showBenchOnField
        self.showRatingsOnCourt = showRatingsOnCourt
        self.showAssignedBasketballLineup = showAssignedBasketballLineup
        self.showBasketballBenchOnCourt = showBasketballBenchOnCourt
        self.showFullNameAndNumberInBasketball = showFullNameAndNumberInBasketball
        self.basketballPeriodFormat = basketballPeriodFormat
        self.basketballYouthEnabled = basketballYouthEnabled
        self.basketballQuartersPlayedEnabled = basketballQuartersPlayedEnabled
        self.basketballRequiredQuartersPlayed = basketballRequiredQuartersPlayed
        self.showOnlyNineBattersAndDH = showOnlyNineBattersAndDH
        self.showSlowSpeedBattingWarnings = showSlowSpeedBattingWarnings
        self.fallBallEnabled = fallBallEnabled
        self.fallBallYouthEnabled = fallBallYouthEnabled
        self.fallBallRunRuleEnabled = fallBallRunRuleEnabled
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
        self.selectedTeamIndex = selectedTeamIndex
        self.teamNames = teamNames
        self.teamSnapshots = teamSnapshots
        self.sportTeamStates = sportTeamStates
    }

    private enum CodingKeys: String, CodingKey {
        case players
        case coaches
        case pitcherID
        case catcherID
        case lineup
        case lineupIDs
        case selectedInning
        case inningLineups
        case inningLineupIDs
        case inningPitcherIDs
        case inningCatcherIDs
        case showRatingsOnField
        case showAssignedLineupTable
        case showFullNameAndNumber
        case showBenchOnField
        case showRatingsOnCourt
        case showAssignedBasketballLineup
        case showBasketballBenchOnCourt
        case showFullNameAndNumberInBasketball
        case basketballPeriodFormat
        case basketballYouthEnabled
        case basketballQuartersPlayedEnabled
        case basketballRequiredQuartersPlayed
        case showOnlyNineBattersAndDH
        case showSlowSpeedBattingWarnings
        case fallBallEnabled
        case fallBallYouthEnabled
        case fallBallRunRuleEnabled
        case battingOrderIDs
        case baseballLineupBatterCount
        case designatedHitterID
        case designatedHitterForID
        case basketballUsesExplicitStartingLineup
        case basketballStartingLineupIDs
        case basketballCourtLineupIDsByPeriod
        case preGameNotes
        case postGameNotes
        case coachNotes
        case selectedSport
        case selectedTeamIndex
        case teamNames
        case teamSnapshots
        case sportTeamStates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        players = try container.decodeIfPresent([Player].self, forKey: .players) ?? []
        coaches = try container.decodeIfPresent([Coach].self, forKey: .coaches) ?? []
        pitcherID = try container.decodeIfPresent(UUID.self, forKey: .pitcherID)
        catcherID = try container.decodeIfPresent(UUID.self, forKey: .catcherID)
        lineup = try container.decodeIfPresent([FieldPosition: Player].self, forKey: .lineup) ?? [:]
        lineupIDs = try container.decode([FieldPosition: UUID].self, forKey: .lineupIDs)
        selectedInning = try container.decodeIfPresent(Int.self, forKey: .selectedInning) ?? 1
        inningLineups = try container.decodeIfPresent([Int: [FieldPosition: Player]].self, forKey: .inningLineups) ?? [:]
        inningLineupIDs = try container.decode([Int: [FieldPosition: UUID]].self, forKey: .inningLineupIDs)
        inningPitcherIDs = try container.decodeIfPresent([Int: UUID].self, forKey: .inningPitcherIDs) ?? [:]
        inningCatcherIDs = try container.decodeIfPresent([Int: UUID].self, forKey: .inningCatcherIDs) ?? [:]
        showRatingsOnField = try container.decodeIfPresent(Bool.self, forKey: .showRatingsOnField) ?? true
        showAssignedLineupTable = try container.decodeIfPresent(Bool.self, forKey: .showAssignedLineupTable) ?? true
        showFullNameAndNumber = try container.decodeIfPresent(Bool.self, forKey: .showFullNameAndNumber) ?? true
        showBenchOnField = try container.decodeIfPresent(Bool.self, forKey: .showBenchOnField) ?? true
        showRatingsOnCourt = try container.decodeIfPresent(Bool.self, forKey: .showRatingsOnCourt)
        showAssignedBasketballLineup = try container.decodeIfPresent(Bool.self, forKey: .showAssignedBasketballLineup)
        showBasketballBenchOnCourt = try container.decodeIfPresent(Bool.self, forKey: .showBasketballBenchOnCourt)
        showFullNameAndNumberInBasketball = try container.decodeIfPresent(Bool.self, forKey: .showFullNameAndNumberInBasketball)
        basketballPeriodFormat = try container.decodeIfPresent(BasketballPeriodFormat.self, forKey: .basketballPeriodFormat)
        basketballYouthEnabled = try container.decodeIfPresent(Bool.self, forKey: .basketballYouthEnabled)
        basketballQuartersPlayedEnabled = try container.decodeIfPresent(Bool.self, forKey: .basketballQuartersPlayedEnabled)
        basketballRequiredQuartersPlayed = try container.decodeIfPresent(Int.self, forKey: .basketballRequiredQuartersPlayed)
        showOnlyNineBattersAndDH = try container.decodeIfPresent(Bool.self, forKey: .showOnlyNineBattersAndDH) ?? false
        showSlowSpeedBattingWarnings = try container.decodeIfPresent(Bool.self, forKey: .showSlowSpeedBattingWarnings) ?? true
        fallBallEnabled = try container.decodeIfPresent(Bool.self, forKey: .fallBallEnabled)
        fallBallYouthEnabled = try container.decodeIfPresent(Bool.self, forKey: .fallBallYouthEnabled)
        fallBallRunRuleEnabled = try container.decodeIfPresent(Bool.self, forKey: .fallBallRunRuleEnabled)
        battingOrderIDs = try container.decodeIfPresent([UUID].self, forKey: .battingOrderIDs) ?? players.map(\.id)
        baseballLineupBatterCount = try container.decodeIfPresent(Int.self, forKey: .baseballLineupBatterCount)
        designatedHitterID = try container.decodeIfPresent(UUID.self, forKey: .designatedHitterID)
        designatedHitterForID = try container.decodeIfPresent(UUID.self, forKey: .designatedHitterForID)
        basketballUsesExplicitStartingLineup = try container.decodeIfPresent(Bool.self, forKey: .basketballUsesExplicitStartingLineup)
        basketballStartingLineupIDs = try container.decodeIfPresent([BasketballPosition: UUID].self, forKey: .basketballStartingLineupIDs)
        basketballCourtLineupIDsByPeriod = try container.decodeIfPresent([Int: [BasketballPosition: UUID]].self, forKey: .basketballCourtLineupIDsByPeriod)
        preGameNotes = try container.decodeIfPresent(String.self, forKey: .preGameNotes)
        postGameNotes = try container.decodeIfPresent(String.self, forKey: .postGameNotes)
        coachNotes = try container.decodeIfPresent(String.self, forKey: .coachNotes)
        selectedSport = try container.decodeIfPresent(SportType.self, forKey: .selectedSport)
        selectedTeamIndex = try container.decodeIfPresent(Int.self, forKey: .selectedTeamIndex)
        teamNames = try container.decodeIfPresent([String].self, forKey: .teamNames)
        teamSnapshots = try container.decodeIfPresent([TeamSnapshot].self, forKey: .teamSnapshots) ?? []
        sportTeamStates = try container.decodeIfPresent([SportType: SportTeamState].self, forKey: .sportTeamStates) ?? [:]
    }
}
