// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PositionMarkerView+Helpers.swift
//
//
//
import SwiftUI

// MARK: - Position Marker Helpers
extension PositionMarkerView {
    // MARK: - Marker Helpers
    // Pitcher and catcher markers need extra width because their labels sit near field edges.
    var markerWidth: CGFloat {
        switch position {
        case .pitcher, .catcher:
            return 132
        default:
            return 96
        }
    }

    // Chooses text color for rating chips based on the rating range.
    func ratingTextColor(for rating: Int) -> Color {
        if rating <= 2 {
            return .white
        } else if rating <= 3 {
            return .white
        } else {
            return .black
        }
    }

    // Builds the player label shown below the position badge.
    // Empty positions show an em dash; assigned positions show either compact or full labels.
    var playerLabel: String {
        // Empty positions show a placeholder instead of a player name.
        guard let player else { return "—" }

        // Split the name so compact mode can show only the first name.
        let nameParts = player.name.split(separator: " ").map(String.init)

        // Include jersey number when present.
        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            return player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }
    }
}
