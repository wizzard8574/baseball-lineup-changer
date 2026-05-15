// Created by Rich Morris on 5/5/26.
// Lineup Changer
// FieldPosition.swift
//
//
//
import Foundation

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
