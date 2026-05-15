// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsView+Helpers.swift
//
//
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View Helpers
extension SettingsView {
    // MARK: - Section Header Styling
    // Shared styling helper for Settings section headers.
    func settingsSectionHeader(_ title: String) -> some View {
        SettingsSectionHeader(title: title)
    }

    // MARK: - Local State Helpers
    // Saves the current team-name edit and dismisses the keyboard.
    func saveEditedTeamName() {
        viewModel.updateSelectedTeamName(editedTeamName)
        isTeamNameFocused = false
    }

    // Keeps the edit field in sync with the selected sport/team slot.
    func syncEditedTeamName() {
        editedTeamName = viewModel.selectedTeamName
        isTeamNameFocused = false
    }

    // Populates local settings values and clamps restored inning count.
    func loadSettingsValues() {
        syncEditedTeamName()
        viewModel.numberOfInnings = min(max(viewModel.numberOfInnings, 1), 12)
    }

    // Keeps inning count in the supported range when changed by the Stepper.
    func clampInningCount(_ newValue: Int) {
        let clampedValue = min(max(newValue, 1), 12)

        if clampedValue != newValue {
            viewModel.numberOfInnings = clampedValue
        }
    }

    // MARK: - Share Helpers
    // Presents the native share sheet for an export file URL.
    func presentShareSheet(url: URL) {
        presentedSheet = .share(url)
    }

    // Exports and shares the lightweight player file.
    func sharePlayer() {
        do {
            // Create the export data, write it to a temp file, then share it.
            let data = viewModel.exportPlayerNameNumberData()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Players.json")
            try data.write(to: url, options: .atomic)
            backupStatusMessage = "Player file ready to share."
            presentShareSheet(url: url)
        } catch {
            backupStatusMessage = "Share player failed: \(error.localizedDescription)"
        }
    }

    // Exports and shares the full player-data/app-state file.
    func sharePlayerData() {
        do {
            let data = viewModel.exportAppStateData()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Player-Data.json")
            try data.write(to: url, options: .atomic)
            backupStatusMessage = "Player data file ready to share."
            presentShareSheet(url: url)
        } catch {
            backupStatusMessage = "Share player data failed: \(error.localizedDescription)"
        }
    }

    // Exports and shares the coach-only file.
    func shareCoaches() {
        do {
            let data = viewModel.exportCoachData()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Coaches.json")
            try data.write(to: url, options: .atomic)
            backupStatusMessage = "Coach file ready to share."
            presentShareSheet(url: url)
        } catch {
            backupStatusMessage = "Share coaches failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Import Handlers
    // Imports either lightweight player data or full player-data backup depending on current mode.
    func handlePlayerImport(_ url: URL) {
        do {
            // Read the selected document into memory before passing it to the view model.
            let data = try Data(contentsOf: url)
            // Route to the correct importer based on which button launched the picker.
            if isImportingPlayerOnly {
                try viewModel.importPlayerNameNumberData(data)
                backupStatusMessage = "Player import complete."
            } else {
                try viewModel.importAppStateData(data)
                backupStatusMessage = "Player data import complete."
            }
        } catch {
            backupStatusMessage = "Import failed: \(error.localizedDescription)"
        }
        // Dismiss the picker/share state after handling the result.
        presentedSheet = nil
    }

    // Imports coach-only JSON data.
    func handleCoachImport(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            try viewModel.importCoachData(data)
            backupStatusMessage = "Coach import complete."
        } catch {
            backupStatusMessage = "Coach import failed: \(error.localizedDescription)"
        }
        presentedSheet = nil
    }

    // Imports GameChanger CSV stats and reports how many players were matched.
    func handleGameChangerImport(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let matchedCount = try viewModel.importGameChangerStatsData(data)
            gameChangerStatusMessage = "Imported GameChanger stats for \(matchedCount) player(s)."
        } catch {
            gameChangerStatusMessage = "Import failed: \(error.localizedDescription)"
        }
        presentedSheet = nil
    }
}

