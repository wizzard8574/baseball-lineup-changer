// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SettingsDataSectionContentView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Settings Data Tool Sections
extension SettingsDataSectionContentView {
    @ViewBuilder
    var selectedDataSectionView: some View {
        switch selectedDataSection {
        case .player:
            playerSection
        case .playerData:
            playerDataSection
        case .coaches:
            coachesSection
        case .gameChanger:
            gameChangerSection
        }
    }

    // MARK: - Player Tools
    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                importPlayer()
            } label: {
                Label("Import Player", systemImage: "square.and.arrow.down")
            }

            Button {
                sharePlayer()
            } label: {
                Label("Share Player", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                isShowingDeletePlayerDialog = true
            } label: {
                Label("Delete Player", systemImage: "trash")
            }

            Text("Import or share players only. Includes player names, numbers, and cell numbers.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Player Data Tools
    private var playerDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                importPlayerData()
            } label: {
                Label("Import Player Data", systemImage: "square.and.arrow.down")
            }

            Button {
                sharePlayerData()
            } label: {
                Label("Share Player Data", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                isShowingDeletePlayerDataConfirmation = true
            } label: {
                Label("Delete Player Data", systemImage: "trash")
            }

            Text("Full backup: players, ratings, lineups, batting order, DH settings, notes, and app settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Coach Tools
    private var coachesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                importCoaches()
            } label: {
                Label("Import Coaches", systemImage: "square.and.arrow.down")
            }

            Button {
                shareCoaches()
            } label: {
                Label("Share Coaches", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                isShowingDeleteCoachDialog = true
            } label: {
                Label("Delete Coach", systemImage: "trash")
            }

            Text("Import or share coaches only. Includes coach names, numbers, roles, and cell numbers.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - GameChanger Tools
    private var gameChangerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                importGameChanger()
            } label: {
                Label("Import GameChanger Stats", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive) {
                viewModel.clearGameChangerStats()
                gameChangerStatusMessage = "GameChanger stats cleared for this team."
            } label: {
                Label("Clear GameChanger Stats", systemImage: "trash")
            }

            Text("Import a GameChanger CSV export. Baseball players are matched by name or number. Basketball players are matched by first name, last initial, or number.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !gameChangerStatusMessage.isEmpty {
                Label(gameChangerStatusMessage, systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }
}
