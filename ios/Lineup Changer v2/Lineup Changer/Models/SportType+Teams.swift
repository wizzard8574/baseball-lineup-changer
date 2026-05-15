// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SportType+Teams.swift
//
//
//
import Foundation

extension SportType {
    var defaultTeamNames: [String] {
        switch self {
        case .baseballSoftball:
            return ["Team 1", "Team 2"]
        case .basketball:
            return ["Basketball Team 1", "Basketball Team 2"]
        case .football:
            return ["Football Team 1", "Football Team 2"]
        case .volleyball:
            return ["Volleyball Team 1", "Volleyball Team 2"]
        case .soccer:
            return ["Soccer Team 1", "Soccer Team 2"]
        }
    }
}
