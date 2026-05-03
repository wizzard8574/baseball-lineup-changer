//
//  SettingsDataSectionView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/2/26.
//

import SwiftUI
import UniformTypeIdentifiers

private enum SettingsDataSection: String, CaseIterable, Identifiable {
    case player = "Player"
    case playerData = "Player Data"
    case coaches = "Coaches"
    case gameChanger = "GameChanger"

    var id: String { rawValue }

    var pickerTitle: String {
        switch self {
        case .player: return "Player"
        case .playerData: return "Player Data"
        case .coaches: return "Coaches"
        case .gameChanger: return "GC Stats"
        }
    }
}

private enum SettingsActiveSheet: Identifiable {
    case playerImport
    case coachImport
    case gameChangerImport
    case share

    var id: String {
        switch self {
        case .playerImport: return "playerImport"
        case .coachImport: return "coachImport"
        case .gameChangerImport: return "gameChangerImport"
        case .share: return "share"
        }
    }
}

struct SettingsDataSectionView: View {
    @ObservedObject var viewModel: LineupViewModel

    @State private var selectedDataSection: SettingsDataSection = .player
    @State private var activeSheet: SettingsActiveSheet?
    @State private var isImportingPlayerOnly = false
    @State private var backupStatusMessage = ""
    @State private var gameChangerStatusMessage = ""
    @State private var shareURL: URL?
    @State private var playerShareURL: URL?
    @State private var isShowingDeletePlayerDialog = false
    @State private var isShowingDeleteCoachDialog = false
    @State private var isShowingDeletePlayerDataConfirmation = false

    var body: some View {
        Section("Data") {
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

            selectedDataSectionView

            if !backupStatusMessage.isEmpty {
                Label(backupStatusMessage, systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .playerImport:
                ImportDocumentPicker(
                    contentTypes: [.json, .data],
                    onPick: { url in
                        do {
                            let data = try Data(contentsOf: url)
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
                        activeSheet = nil
                    },
                    onCancel: {
                        backupStatusMessage = "Import cancelled."
                        activeSheet = nil
                    }
                )

            case .coachImport:
                ImportDocumentPicker(
                    contentTypes: [.json, .data],
                    onPick: { url in
                        do {
                            let data = try Data(contentsOf: url)
                            try viewModel.importCoachData(data)
                            backupStatusMessage = "Coach import complete."
                        } catch {
                            backupStatusMessage = "Coach import failed: \(error.localizedDescription)"
                        }
                        activeSheet = nil
                    },
                    onCancel: {
                        backupStatusMessage = "Coach import cancelled."
                        activeSheet = nil
                    }
                )

            case .gameChangerImport:
                ImportDocumentPicker(
                    contentTypes: [.commaSeparatedText, .plainText, .data],
                    onPick: { url in
                        do {
                            let data = try Data(contentsOf: url)
                            let matchedCount = try viewModel.importGameChangerStatsData(data)
                            gameChangerStatusMessage = "Imported GameChanger stats for \(matchedCount) player(s)."
                        } catch {
                            gameChangerStatusMessage = "Import failed: \(error.localizedDescription)"
                        }
                        activeSheet = nil
                    },
                    onCancel: {
                        gameChangerStatusMessage = "Import cancelled."
                        activeSheet = nil
                    }
                )

            case .share:
                if let shareURL {
                    ActivityView(activityItems: [shareURL])
                } else {
                    Text("No backup file available to share.")
                }
            }
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

    private var selectedDataSectionView: AnyView {
        switch selectedDataSection {
        case .player:
            return AnyView(playerSection)
        case .playerData:
            return AnyView(playerDataSection)
        case .coaches:
            return AnyView(coachesSection)
        case .gameChanger:
            return AnyView(gameChangerSection)
        }
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                isImportingPlayerOnly = true
                activeSheet = .playerImport
            } label: {
                Label("Import Player", systemImage: "square.and.arrow.down")
            }

            Button {
                do {
                    let data = viewModel.exportPlayerNameNumberData()
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Players.json")
                    try data.write(to: url, options: .atomic)
                    playerShareURL = url
                    shareURL = url
                    activeSheet = .share
                    backupStatusMessage = "Player file ready to share."
                } catch {
                    backupStatusMessage = "Share player failed: \(error.localizedDescription)"
                }
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

    private var playerDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                isImportingPlayerOnly = false
                activeSheet = .playerImport
            } label: {
                Label("Import Player Data", systemImage: "square.and.arrow.down")
            }

            Button {
                do {
                    let data = viewModel.exportAppStateData()
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Player-Data.json")
                    try data.write(to: url, options: .atomic)
                    shareURL = url
                    activeSheet = .share
                    backupStatusMessage = "Player data file ready to share."
                } catch {
                    backupStatusMessage = "Share player data failed: \(error.localizedDescription)"
                }
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

    private var coachesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                activeSheet = .coachImport
            } label: {
                Label("Import Coaches", systemImage: "square.and.arrow.down")
            }

            Button {
                do {
                    let data = viewModel.exportCoachData()
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Coaches.json")
                    try data.write(to: url, options: .atomic)
                    shareURL = url
                    activeSheet = .share
                    backupStatusMessage = "Coach file ready to share."
                } catch {
                    backupStatusMessage = "Share coaches failed: \(error.localizedDescription)"
                }
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

    private var gameChangerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                activeSheet = .gameChangerImport
            } label: {
                Label("Import GameChanger Stats", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive) {
                viewModel.clearGameChangerStats()
                gameChangerStatusMessage = "GameChanger stats cleared."
            } label: {
                Label("Clear GameChanger Stats", systemImage: "trash")
            }

            Text("Import a GameChanger CSV export. Players are matched by first and last name.")
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
