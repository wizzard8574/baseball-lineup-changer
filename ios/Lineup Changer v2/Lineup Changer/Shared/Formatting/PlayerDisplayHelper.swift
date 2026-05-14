// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayerDisplayHelper.swift
//
//
//
import SwiftUI

// MARK: - Player Display Helpers

// Shared formatting helpers used by player rows, lineup views, field assignment views, and PDFs.

struct PlayerDisplayHelper {
    // Builds the main player label and optionally appends guest status text.
    static func displayLabel(for player: Player, showFullNameAndNumber: Bool, includeStatus: Bool = true) -> String {
        // Start with the display mode-specific name/number label.
        let baseLabel = baseDisplayLabel(for: player, showFullNameAndNumber: showFullNameAndNumber)
        return includeStatus && player.status == .guest ? "\(baseLabel) (Guest)" : baseLabel
    }

    // Builds the name/number portion of a player label without status text.
    static func baseDisplayLabel(for player: Player, showFullNameAndNumber: Bool) -> String {
        // Split the name so compact mode can use the first name only.
        let nameParts = player.name.split(separator: " ").map(String.init)

        // Full mode shows complete name and optional jersey number.
        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            return player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }
    }

    // Returns short inline status text for non-active players.
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

    // Chooses a visual color for inline status text.
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

    // Creates a compact summary of all rated defensive positions.
    static func positionSummary(for player: Player) -> String {
        // Preserve FieldPosition order so summaries are predictable.
        FieldPosition.allCases
            .compactMap { position in
                guard let rating = player.positionRatings[position] else { return nil }
                return "\(position.rawValue): \(rating)"
            }
            .joined(separator: " • ")
    }

    // Converts each field position into the common baseball scorebook numbering label.
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

    // Displays the player's rating for a field position, or Manual when no rating exists.
    static func ratingLabel(for player: Player, at position: FieldPosition) -> String {
        // Manual assignments may not have a stored rating for that position.
        guard let rating = player.positionRatings[position] else { return "Manual" }
        return "Rating \(rating)"
    }
}
