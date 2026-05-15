// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayerDisplayHelper.swift
//
//
//
import SwiftUI

// MARK: - Player Display Helpers
struct PlayerDisplayHelper {
    static func displayLabel(for player: Player, showFullNameAndNumber: Bool, includeStatus: Bool = true) -> String {
        let baseLabel = baseDisplayLabel(for: player, showFullNameAndNumber: showFullNameAndNumber)
        return includeStatus && player.status == .guest ? "\(baseLabel) (Guest)" : baseLabel
    }

    static func baseDisplayLabel(for player: Player, showFullNameAndNumber: Bool) -> String {
        let nameParts = player.name.split(separator: " ").map(String.init)

        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            return player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }
    }

    static func inlineStatusText(for player: Player) -> String? {
        switch player.status {
        case .active:
            return nil
        case .guest:
            return "(Guest)"
        case .injured:
            return "(Injured)"
        case .unavailable:
            return "(Unavailable)"
        }
    }

    static func inlineStatusColor(for player: Player) -> Color {
        switch player.status {
        case .guest, .injured:
            return .red
        case .unavailable:
            return .orange
        case .active:
            return .secondary
        }
    }

    static func positionSummary(for player: Player) -> String {
        FieldPosition.allCases
            .compactMap { position in
                guard let rating = player.positionRatings[position] else { return nil }
                return "\(position.rawValue): \(rating)"
            }
            .joined(separator: " • ")
    }

    static func basketballPositionSummary(for player: Player) -> String {
        let positions = basketballPositionSummaryValue(for: player)
        return positions.isEmpty ? "" : "Positions: \(positions)"
    }

    static func basketballPositionSummaryValue(for player: Player) -> String {
        BasketballPosition.allCases
            .compactMap { position in
                guard let rating = player.basketballPositionRatings[position] else { return nil }
                return "\(position.rawValue): \(rating)"
            }
            .joined(separator: " • ")
    }

    static func assignedLineupLabel(for position: FieldPosition) -> String {
        switch position {
        case .pitcher:
            return "P - 1"
        case .catcher:
            return "C - 2"
        case .firstBase:
            return "1B - 3"
        case .secondBase:
            return "2B - 4"
        case .thirdBase:
            return "3B - 5"
        case .shortstop:
            return "SS - 6"
        case .leftField:
            return "LF - 7"
        case .centerField:
            return "CF - 8"
        case .rightField:
            return "RF - 9"
        }
    }

    static func ratingLabel(for player: Player, at position: FieldPosition) -> String {
        guard let rating = player.positionRatings[position] else { return "Manual" }
        return "Rating \(rating)"
    }
}
