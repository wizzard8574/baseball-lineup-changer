// Created by Rich Morris on 5/5/26.
// Lineup Changer
// GameChangerStats.swift
//
//
//
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

// MARK: - Basketball GameChanger Stats Model

// Imported GameChanger basketball averages stored on a Player.
// String values preserve the original CSV formatting exactly as imported.
struct PlayerBasketballGameChangerStats: Codable, Equatable {
    var ppg: String = ""
    var topg: String = ""
    var rpg: String = ""
    var apg: String = ""
    var spg: String = ""
    var bpg: String = ""
    var trueShootingPercentage: String = ""
    var assistTurnoverRatio: String = ""

    var displayText: String {
        "Stats: PPG \(ppg) • TOPG \(topg) • RPG \(rpg) • APG \(apg) • SPG \(spg) • BPG \(bpg) • TS% \(trueShootingPercentage) • AST/TO \(assistTurnoverRatio)"
    }

    var lineupDisplayText: String {
        "Stats: PPG \(ppg) • TOPG \(topg) • RPG \(rpg) • APG \(apg)\nSPG \(spg) • BPG \(bpg) • TS% \(trueShootingPercentage) • AST/TO \(assistTurnoverRatio)"
    }
}
