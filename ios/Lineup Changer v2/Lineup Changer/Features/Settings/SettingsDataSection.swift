// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsDataSection.swift
//
//
//
// SettingsDataSection defines the segmented-control options for Settings data tools.
import Foundation

// MARK: - Settings Data Section
// Segmented-control options for the import/export data tools.
enum SettingsDataSection: String, CaseIterable, Identifiable {
    // Lightweight player sharing: name, number, and cell.
    case player = "Player"
    // Full player-related app-state backup.
    case playerData = "Player Data"
    // Coach-only import/export tools.
    case coaches = "Coaches"
    // GameChanger CSV stat import and cleanup tools.
    case gameChanger = "GameChanger"

    // Allows SettingsDataSection to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }

    // Short labels used by the segmented picker.
    var pickerTitle: String {
        switch self {
        case .player: return "Player"
        case .playerData: return "Player Data"
        case .coaches: return "Coaches"
        case .gameChanger: return "GC Stats"
        }
    }
}
