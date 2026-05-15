// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SportType+Placeholders.swift
//
//
//
import Foundation

extension SportType {
    var playingSurfacePlaceholderMessage: String {
        "\(rawValue) \(playingSurfaceTitle.lowercased()) and lineup features will be added here."
    }

    var playersPlaceholderTitle: String {
        "\(rawValue) Players Coming Soon"
    }

    var playersPlaceholderMessage: String {
        "Player setup for this sport will be available in a future update."
    }

    var lineupPlaceholderTitle: String {
        "\(rawValue) Lineup Coming Soon"
    }

    var lineupPlaceholderMessage: String {
        "Lineup setup for this sport will be available in a future update."
    }
}
