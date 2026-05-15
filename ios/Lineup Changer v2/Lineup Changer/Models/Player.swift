// Created by Rich Morris on 5/5/26.
// Lineup Changer
// Player.swift
//
//
//
import Foundation

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
    var basketballPositionRatings: [BasketballPosition: Int]
    var speedRating: Int
    // Optional imported stats and coach notes.
    var gameChangerStats: PlayerGameChangerStats?
    var basketballGameChangerStats: PlayerBasketballGameChangerStats?
    var notes: String

    // Creates a player with sensible defaults for new roster entries.
    init(id: UUID = UUID(),
         name: String,
         number: String = "",
         cell: String = "",
         status: PlayerStatus = .active,
         positionRatings: [FieldPosition: Int] = [:],
         basketballPositionRatings: [BasketballPosition: Int] = [:],
         speedRating: Int = 1,
         gameChangerStats: PlayerGameChangerStats? = nil,
         basketballGameChangerStats: PlayerBasketballGameChangerStats? = nil,
         notes: String = "") {
        self.id = id
        self.name = name
        self.number = number
        self.cell = cell
        self.notes = notes
        self.status = status
        self.positionRatings = positionRatings
        self.basketballPositionRatings = basketballPositionRatings
        self.speedRating = speedRating
        self.gameChangerStats = gameChangerStats
        self.basketballGameChangerStats = basketballGameChangerStats
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
        case basketballPositionRatings
        case speedRating
        case gameChangerStats
        case basketballGameChangerStats
        case notes
    }

    // Custom decoder keeps player records resilient when optional details are absent.
    init(from decoder: Decoder) throws {
        // Decode each field defensively so older app-state files can still load.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        number = try container.decodeIfPresent(String.self, forKey: .number) ?? ""
        cell = try container.decodeIfPresent(String.self, forKey: .cell) ?? ""
        status = try container.decodeIfPresent(PlayerStatus.self, forKey: .status) ?? .active
        positionRatings = try container.decodeIfPresent([FieldPosition: Int].self, forKey: .positionRatings) ?? [:]
        basketballPositionRatings = try container.decodeIfPresent([BasketballPosition: Int].self, forKey: .basketballPositionRatings) ?? [:]
        speedRating = try container.decodeIfPresent(Int.self, forKey: .speedRating) ?? 1
        gameChangerStats = try container.decodeIfPresent(PlayerGameChangerStats.self, forKey: .gameChangerStats)
        basketballGameChangerStats = try container.decodeIfPresent(PlayerBasketballGameChangerStats.self, forKey: .basketballGameChangerStats)
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
        try container.encode(basketballPositionRatings, forKey: .basketballPositionRatings)
        try container.encode(speedRating, forKey: .speedRating)
        try container.encodeIfPresent(gameChangerStats, forKey: .gameChangerStats)
        try container.encodeIfPresent(basketballGameChangerStats, forKey: .basketballGameChangerStats)
        try container.encode(notes, forKey: .notes)
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
    // Guest players stay in the roster but are not eligible for field or lineup assignment.
    case guest
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
