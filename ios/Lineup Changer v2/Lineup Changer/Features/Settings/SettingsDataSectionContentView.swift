// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsDataSectionContentView.swift
//
//
//
// SettingsDataSectionContentView contains the Settings tab data-management tools.
import SwiftUI

// MARK: - Settings Data Section Content View
// Data-management section used inside SettingsView.
struct SettingsDataSectionContentView: View {
    // Shared app state and import/export/delete methods.
    @ObservedObject var viewModel: LineupViewModel
    // Status text shared with the parent SettingsView.
    @Binding var backupStatusMessage: String
    @Binding var gameChangerStatusMessage: String

    // Action closures supplied by SettingsView.
    let importPlayer: () -> Void
    let importPlayerData: () -> Void
    let importCoaches: () -> Void
    let importGameChanger: () -> Void
    let sharePlayer: () -> Void
    let sharePlayerData: () -> Void
    let shareCoaches: () -> Void

    // Local UI state for segmented data section and destructive confirmation dialogs.
    @State var selectedDataSection: SettingsDataSection = .player
    @State var isShowingDeletePlayerDialog = false
    @State var isShowingDeleteCoachDialog = false
    @State var isShowingDeletePlayerDataConfirmation = false

    // MARK: - Body
    var body: some View {
        dataSectionContent
    }
}
