// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Settings Sections
extension SettingsView {
    var settingsListContent: some View {
        List {
            teamNameSection
            sportSelectionSection
            baseballSettingsSection
            basketballSettingsSection
            dataSection
            AboutSettingsSection()
        }
        .scrollContentBackground(.hidden)
    }

    private var teamNameSection: some View {
        Section {
            // Switches between the two saved team slots.
            TeamPickerView(viewModel: viewModel)

            // Editable team name field.
            TextField("Team name", text: $editedTeamName)
                .textFieldStyle(.roundedBorder)
                .focused($isTeamNameFocused)
                .submitLabel(.done)
                .onSubmit {
                    saveEditedTeamName()
                }

            // Explicit save button for team-name changes.
            Button("Save Team Name") {
                saveEditedTeamName()
            }
        }
        .id(teamEditorIdentity)
    }

    private var sportSelectionSection: some View {
        Section(header: settingsSectionHeader("Sport - \(viewModel.selectedSport.rawValue)")) {
            // Icon-only segmented picker for sport modes.
            Picker("Sport", selection: Binding(
                get: { viewModel.selectedSport },
                set: { sport in
                    viewModel.selectSport(sport)
                    syncEditedTeamName()
                }
            )) {
                ForEach(SportType.allCases) { sport in
                    Image(systemName: sport.settingsIconName)
                        .tag(sport)
                }
            }
            .pickerStyle(.segmented)

            // Clarifies that non-baseball sports are placeholders for now.
            Text("Current sport selection only. Field, lineup, player positions, and sport-specific rules will be updated in later phases.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var baseballSettingsSection: some View {
        // Baseball/softball-specific settings are hidden for sports that do not support them.
        if viewModel.selectedSport.showsBaseballSettings {
            BaseballSettingsSections(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var basketballSettingsSection: some View {
        if viewModel.selectedSport.showsBasketballSettings {
            BasketballSettingsSections(viewModel: viewModel)
        }
    }

    private var dataSection: some View {
        SettingsDataSectionContentView(
            viewModel: viewModel,
            backupStatusMessage: $backupStatusMessage,
            gameChangerStatusMessage: $gameChangerStatusMessage,
            importPlayer: {
                // Import only player names, numbers, and cell numbers.
                isImportingPlayerOnly = true
                presentedSheet = .playerImport
            },
            importPlayerData: {
                // Import a full player-data/app-state backup.
                isImportingPlayerOnly = false
                presentedSheet = .playerImport
            },
            importCoaches: {
                // Import coach-only data.
                presentedSheet = .coachImport
            },
            importGameChanger: {
                // Import GameChanger CSV stats.
                presentedSheet = .gameChangerImport
            },
            sharePlayer: sharePlayer,
            sharePlayerData: sharePlayerData,
            shareCoaches: shareCoaches
        )
    }
}
