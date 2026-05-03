//
//  Models.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import Foundation

// MARK: - Model

struct PlayerGameChangerStats: Codable, Equatable {
    var avg: String = ""
    var obp: String = ""
    var ops: String = ""
    var slg: String = ""
    var hits: String = ""
    var rbi: String = ""
    var runs: String = ""
    var walks: String = ""
    var strikeouts: String = ""

    var displayText: String {
        "Stats: AVG \(avg) • OBP \(obp) • OPS \(ops) • SLG \(slg) • H \(hits) • RBI \(rbi) • R \(runs) • BB \(walks) • SO \(strikeouts)"
    }
}

enum PlayerStatus: String, CaseIterable, Codable {
    case active
    case injured
    case unavailable
    case guest
}

enum SportType: String, CaseIterable, Identifiable, Codable {
    case baseballSoftball = "Baseball/Softball"
    case basketball = "Basketball"
    case football = "Football"
    case volleyball = "Volleyball"
    case soccer = "Soccer"

    var id: String { rawValue }
}

enum FieldPosition: String, CaseIterable, Identifiable, Codable {
    case pitcher = "P"
    case catcher = "C"
    case firstBase = "1B"
    case secondBase = "2B"
    case thirdBase = "3B"
    case shortstop = "SS"
    case leftField = "LF"
    case centerField = "CF"
    case rightField = "RF"

    var id: String { rawValue }

    static var autoAssignedPositions: [FieldPosition] {
        [.firstBase, .secondBase, .thirdBase, .shortstop, .leftField, .centerField, .rightField]
    }
}

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var number: String
    var cell: String
    var status: PlayerStatus
    var positionRatings: [FieldPosition: Int]
    var speedRating: Int
    var gameChangerStats: PlayerGameChangerStats?
    var notes: String

    init(id: UUID = UUID(),
         name: String,
         number: String = "",
         cell: String = "",
         status: PlayerStatus = .active,
         positionRatings: [FieldPosition: Int] = [:],
         speedRating: Int = 1,
         gameChangerStats: PlayerGameChangerStats? = nil,
         notes: String = "") {
        self.id = id
        self.name = name
        self.number = number
        self.cell = cell
        self.notes = notes
        self.status = status
        self.positionRatings = positionRatings
        self.speedRating = speedRating
        self.gameChangerStats = gameChangerStats
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case number
        case cell
        case status
        case positionRatings
        case speedRating
        case gameChangerStats
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        number = try container.decodeIfPresent(String.self, forKey: .number) ?? ""
        cell = try container.decodeIfPresent(String.self, forKey: .cell) ?? ""
        status = try container.decodeIfPresent(PlayerStatus.self, forKey: .status) ?? .active
        positionRatings = try container.decodeIfPresent([FieldPosition: Int].self, forKey: .positionRatings) ?? [:]
        speedRating = try container.decodeIfPresent(Int.self, forKey: .speedRating) ?? 1
        gameChangerStats = try container.decodeIfPresent(PlayerGameChangerStats.self, forKey: .gameChangerStats)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(number, forKey: .number)
        try container.encode(cell, forKey: .cell)
        try container.encode(status, forKey: .status)
        try container.encode(positionRatings, forKey: .positionRatings)
        try container.encode(speedRating, forKey: .speedRating)
        try container.encodeIfPresent(gameChangerStats, forKey: .gameChangerStats)
        try container.encode(notes, forKey: .notes)
    }
}

struct Coach: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var number: String
    var cell: String
    var role: String

    init(id: UUID = UUID(), name: String, number: String = "", cell: String = "", role: String = "") {
        self.id = id
        self.name = name
        self.number = number
        self.cell = cell
        self.role = role
    }
}

struct AppState: Codable {
    var players: [Player]
    var coaches: [Coach]
    var pitcherID: UUID?
    var catcherID: UUID?
    var lineup: [FieldPosition: Player]
    var selectedInning: Int
    var inningLineups: [Int: [FieldPosition: Player]]
    var inningPitcherIDs: [Int: UUID]
    var inningCatcherIDs: [Int: UUID]
    var showRatingsOnField: Bool
    var showAssignedLineupTable: Bool
    var showFullNameAndNumber: Bool
    var showBenchOnField: Bool
    var showOnlyNineBattersAndDH: Bool
    var showSlowSpeedBattingWarnings: Bool
    var fallBallEnabled: Bool?
    var fallBallYouthEnabled: Bool?
    var battingOrderIDs: [UUID]
    var designatedHitterID: UUID?
    var designatedHitterForID: UUID?
    var preGameNotes: String?
    var postGameNotes: String?
    var coachNotes: String?
    var selectedSport: SportType?
    var selectedTeamIndex: Int?
    var teamNames: [String]?
    var teamSnapshots: [TeamSnapshot]
}

struct TeamSnapshot: Codable {
    var players: [Player]
    var coaches: [Coach]?
    var pitcherID: UUID?
    var catcherID: UUID?
    var lineup: [FieldPosition: Player]
    var selectedInning: Int
    var inningLineups: [Int: [FieldPosition: Player]]
    var inningPitcherIDs: [Int: UUID]
    var inningCatcherIDs: [Int: UUID]
    var battingOrderIDs: [UUID]
    var designatedHitterID: UUID?
    var designatedHitterForID: UUID?
    var preGameNotes: String?
    var postGameNotes: String?
    var coachNotes: String?
    var selectedSport: SportType?
}
