// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsPresentedSheet.swift
//
//
//
// SettingsPresentedSheet defines the modal routes used by SettingsView.
import Foundation

// MARK: - Settings Presented Sheet
// Sheet routes used by SettingsView.
enum SettingsPresentedSheet: Identifiable {
    // Document picker routes.
    case playerImport
    case coachImport
    case gameChangerImport
    // Share sheet route with the generated file URL.
    case share(URL)

    // Stable ID required by SwiftUI's item-based sheet API.
    var id: String {
        switch self {
        case .playerImport: return "playerImport"
        case .coachImport: return "coachImport"
        case .gameChangerImport: return "gameChangerImport"
        case .share(let url): return "share-\(url.lastPathComponent)"
        }
    }
}
