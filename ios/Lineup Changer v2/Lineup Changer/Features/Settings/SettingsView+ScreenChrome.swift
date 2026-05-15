// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsView+ScreenChrome.swift
//
//
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings Screen Chrome
extension SettingsView {
    var settingsScreen: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed app background.
                AppSportsBackground()

                settingsListContent
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: "Settings", systemImage: "gearshape.fill")
                }

                // Keyboard accessory button for saving and dismissing the team-name field.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        viewModel.updateSelectedTeamName(editedTeamName)
                        isTeamNameFocused = false
                    }
                }
            }
            // Populate local settings values and restore the saved inning count when Settings opens.
            .onAppear {
                loadSettingsValues()
            }
            // Refresh the team-name field when switching teams.
            .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                syncEditedTeamName()
            }
            // Refresh the edit field when sport changes replace the active team slots.
            .onChange(of: viewModel.teamNames) { _, _ in
                syncEditedTeamName()
            }
            // Segmented pickers can redraw before the local text field sees the new sport state.
            .onChange(of: viewModel.selectedSport) { _, _ in
                syncEditedTeamName()
            }
            // Keep inning count valid and persisted when changed by the Stepper.
            .onChange(of: viewModel.numberOfInnings) { _, newValue in
                clampInningCount(newValue)
            }
        }
        // Presents document pickers and share sheets for Settings workflows.
        .sheet(item: $presentedSheet) { sheet in
            settingsSheetContent(sheet)
        }
    }
}
