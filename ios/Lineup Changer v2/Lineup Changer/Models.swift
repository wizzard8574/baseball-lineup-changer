// Created by Rich Morris on 5/5/26.
// Lineup Changer
// Models.swift
//
//
//
// Models.swift contains the Codable data models and enums used throughout the app.
// These types represent players, coaches, sports, field positions, saved app state,
// and per-team snapshots used by persistence and import/export features.
import Foundation

// MARK: - GameChanger Stats Model

// Imported GameChanger batting stats stored on a Player.
// String values preserve the original CSV formatting exactly as imported.

struct PlayerGameChangerStats: Codable, Equatable {
    // Batting stat fields imported from GameChanger CSV exports.
    var avg: String = ""
    var obp: String = ""
    var ops: String = ""
    var slg: String = ""
    var hits: String = ""
    var rbi: String = ""
    var runs: String = ""
    var walks: String = ""
    var strikeouts: String = ""

    // Compact one-line summary used in lineup/player UI.
    var displayText: String {
        "Stats: AVG \(avg) • OBP \(obp) • OPS \(ops) • SLG \(slg) • H \(hits) • RBI \(rbi) • R \(runs) • BB \(walks) • SO \(strikeouts)"
    }
}

// MARK: - Player Status
// Player availability states used to determine lineup eligibility.

enum PlayerStatus: String, CaseIterable, Codable {
    // Available for normal lineup and field assignment.
    case active
    // Not eligible for field or lineup assignment until restored.
    case injured
    // Temporarily not available for the current game or lineup.
    case unavailable
    // Guest players remain eligible while being visually identified as guests.
    case guest
}

// MARK: - Sport Type
// Sports supported or planned by the app.

enum SportType: String, CaseIterable, Identifiable, Codable {
    // Currently implemented sport mode.
    case baseballSoftball = "Baseball/Softball"
    // Future sport placeholder.
    case basketball = "Basketball"
    case football = "Football"
    case volleyball = "Volleyball"
    case soccer = "Soccer"

    // Allows SportType to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }
}

// MARK: - Field Position
// Baseball/softball defensive positions used for ratings and lineup assignment.

enum FieldPosition: String, CaseIterable, Identifiable, Codable {
    // Battery positions.
    case pitcher = "P"
    case catcher = "C"
    // Infield positions.
    case firstBase = "1B"
    case secondBase = "2B"
    case thirdBase = "3B"
    case shortstop = "SS"
    // Outfield positions.
    case leftField = "LF"
    case centerField = "CF"
    case rightField = "RF"

    // Allows FieldPosition to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }

    // Positions automatically filled by standard lineup generation.
    // Pitcher and catcher are excluded because they are manually controlled in standard mode.
    static var autoAssignedPositions: [FieldPosition] {
        [.firstBase, .secondBase, .thirdBase, .shortstop, .leftField, .centerField, .rightField]
    }
}

// MARK: - Player Model
// Core roster model used throughout the app.

struct Player: Identifiable, Codable, Equatable, Hashable{
    // Stable identifier used for persistence, lineup references, and SwiftUI lists.
    let id: UUID
    // Basic player profile fields.
    var name: String
    var number: String
    var cell: String
    // Availability and lineup-related values.
    var status: PlayerStatus
    var positionRatings: [FieldPosition: Int]
    var speedRating: Int
    // Optional imported stats and coach notes.
    var gameChangerStats: PlayerGameChangerStats?
    var notes: String

    // Creates a player with sensible defaults for new roster entries.
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

    // MARK: - Codable
    // Explicit coding keys keep persistence stable across model changes.
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

    // Custom decoder provides defaults for fields that may be missing in older saved data.
    init(from decoder: Decoder) throws {
        // Decode each field defensively so older app-state files can still load.
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

    // Custom encoder writes the full current player model.
    func encode(to encoder: Encoder) throws {
        // Encode every persisted player field, omitting optional stats only when nil.
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

// MARK: - Player Identity Helpers

extension Player {
    // Players are considered equal when their stable IDs match.
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }

    // Hashing by ID keeps SwiftUI list identity stable.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Coach Model
// Coach contact/profile model used by coach lists and message/call actions.

struct Coach: Identifiable, Codable, Equatable , Hashable{
    // Stable identifier used for persistence and SwiftUI lists.
    let id: UUID
    // Coach profile and contact fields.
    var name: String
    var number: String
    var cell: String
    var role: String

    // Creates a coach with optional number, cell, and role values.
    init(id: UUID = UUID(), name: String, number: String = "", cell: String = "", role: String = "") {
        self.id = id
        self.name = name
        self.number = number
        self.cell = cell
        self.role = role
    }
}

// MARK: - App State Model
// Full persisted app state saved to UserDefaults.
// Includes global settings plus current/team-specific data for compatibility with older saves.

struct AppState: Codable {
    // Legacy/current team roster and staff data.
    var players: [Player]
    var coaches: [Coach]
    // Current defensive assignment state.
    var pitcherID: UUID?
    var catcherID: UUID?
    var lineup: [FieldPosition: Player]
    // Inning-specific lineup storage.
    var selectedInning: Int
    var inningLineups: [Int: [FieldPosition: Player]]
    var inningPitcherIDs: [Int: UUID]
    var inningCatcherIDs: [Int: UUID]
    // Global display settings.
    var showRatingsOnField: Bool
    var showAssignedLineupTable: Bool
    var showFullNameAndNumber: Bool
    var showBenchOnField: Bool
    var showOnlyNineBattersAndDH: Bool
    var showSlowSpeedBattingWarnings: Bool
    // Game format and lineup generation settings.
    var fallBallEnabled: Bool?
    var fallBallYouthEnabled: Bool?
    // Batting order and designated hitter state.
    var battingOrderIDs: [UUID]
    var designatedHitterID: UUID?
    var designatedHitterForID: UUID?
    // Notes and selected sport.
    var preGameNotes: String?
    var postGameNotes: String?
    var coachNotes: String?
    var selectedSport: SportType?
    // Multi-team persistence support.
    var selectedTeamIndex: Int?
    var teamNames: [String]?
    var teamSnapshots: [TeamSnapshot]
}

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
    // Team inning-specific lineup storage.
    var selectedInning: Int
    var inningLineups: [Int: [FieldPosition: Player]]
    var inningPitcherIDs: [Int: UUID]
    var inningCatcherIDs: [Int: UUID]
    // Team batting order and DH state.
    var battingOrderIDs: [UUID]
    var designatedHitterID: UUID?
    var designatedHitterForID: UUID?
    // Team notes and selected sport.
    var preGameNotes: String?
    var postGameNotes: String?
    var coachNotes: String?
    var selectedSport: SportType?
}
