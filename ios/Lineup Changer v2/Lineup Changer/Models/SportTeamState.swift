//
//  SportTeamState.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/8/26.
//

import Foundation

// MARK: - Sport Team State Model
// Stores each sport's two team slots and the selected team for that sport.

struct SportTeamState: Codable {
    var selectedTeamIndex: Int
    var teamNames: [String]
    var teamSnapshots: [TeamSnapshot]
    var hasCustomTeamNames: Bool

    init(selectedTeamIndex: Int = 0,
         teamNames: [String],
         teamSnapshots: [TeamSnapshot],
         hasCustomTeamNames: Bool = false) {
        self.selectedTeamIndex = selectedTeamIndex
        self.teamNames = teamNames
        self.teamSnapshots = teamSnapshots
        self.hasCustomTeamNames = hasCustomTeamNames
    }

    private enum CodingKeys: String, CodingKey {
        case selectedTeamIndex
        case teamNames
        case teamSnapshots
        case hasCustomTeamNames
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedTeamIndex = try container.decodeIfPresent(Int.self, forKey: .selectedTeamIndex) ?? 0
        teamNames = try container.decodeIfPresent([String].self, forKey: .teamNames) ?? []
        teamSnapshots = try container.decodeIfPresent([TeamSnapshot].self, forKey: .teamSnapshots) ?? []
        hasCustomTeamNames = try container.decodeIfPresent(Bool.self, forKey: .hasCustomTeamNames) ?? false
    }
}
