// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsDataSectionContentView+Chrome.swift
//
//
//
import SwiftUI

// MARK: - Settings Data Section Chrome
extension SettingsDataSectionContentView {
    var dataSectionContent: some View {
        Section(header: SettingsSectionHeader(title: "Data")) {
            dataSectionPicker
            selectedDataSectionView
            backupStatusLabel
        }
        .confirmationDialog("Delete Player", isPresented: $isShowingDeletePlayerDialog, titleVisibility: .visible) {
            ForEach(viewModel.players) { player in
                Button(viewModel.displayLabel(for: player), role: .destructive) {
                    viewModel.deletePlayer(playerID: player.id)
                    backupStatusMessage = "Deleted \(player.name)."
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose a player to delete.")
        }
        .confirmationDialog("Delete Coach", isPresented: $isShowingDeleteCoachDialog, titleVisibility: .visible) {
            ForEach(viewModel.coaches) { coach in
                Button(coach.name, role: .destructive) {
                    viewModel.deleteCoach(coachID: coach.id)
                    backupStatusMessage = "Deleted \(coach.name)."
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose a coach to delete.")
        }
        .confirmationDialog("Delete All Player Data?", isPresented: $isShowingDeletePlayerDataConfirmation, titleVisibility: .visible) {
            Button("Delete Players Only", role: .destructive) {
                viewModel.deleteAllPlayersOnly()
                backupStatusMessage = "Players deleted. Coaches were kept."
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes players and player-related lineup data from the current team. Coaches are kept.")
        }
    }

    private var dataSectionPicker: some View {
        Picker("Data Section", selection: $selectedDataSection) {
            ForEach(SettingsDataSection.allCases) { section in
                Text(section.pickerTitle).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedDataSection) { _, _ in
            backupStatusMessage = ""
            gameChangerStatusMessage = ""
        }
    }

    @ViewBuilder
    private var backupStatusLabel: some View {
        if !backupStatusMessage.isEmpty {
            Label(backupStatusMessage, systemImage: "checkmark.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
