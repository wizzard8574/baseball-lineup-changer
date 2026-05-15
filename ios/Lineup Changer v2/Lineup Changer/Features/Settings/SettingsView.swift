// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsView.swift
//
//
//
// SettingsView.swift contains the Settings tab UI.
// It manages team names, sport selection, lineup display settings, batting-order options,
// Fall Ball options, import/export actions, GameChanger stat imports, and app information.
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View
// Main Settings tab screen.
struct SettingsView: View {
    // Shared app state containing settings, team names, import/export methods, and sport state.
    @ObservedObject var viewModel: LineupViewModel
    // Local editable team name so text-field edits can be saved intentionally.
    @State var editedTeamName = ""
    // Controls document picker and share-sheet presentation.
    @State var presentedSheet: SettingsPresentedSheet?
    // Distinguishes lightweight player imports from full player-data imports.
    @State var isImportingPlayerOnly = false
    // User-facing status messages for backup/import/export actions.
    @State var backupStatusMessage = ""
    @State var gameChangerStatusMessage = ""
    // Tracks keyboard focus for the editable team-name field.
    @FocusState var isTeamNameFocused: Bool
    // Changes whenever active sport/team labels change so stale segmented controls are discarded.
    var teamEditorIdentity: String {
        "\(viewModel.selectedSport.rawValue)-\(viewModel.selectedTeamIndex)-\(viewModel.teamNames.joined(separator: "|"))"
    }

    // MARK: - Body
    var body: some View {
        settingsScreen
    }
}
