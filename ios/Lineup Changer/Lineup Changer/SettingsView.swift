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

struct SettingsView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State private var editedTeamName = ""
    @State private var presentedSheet: SettingsPresentedSheet?
    @State private var isImportingPlayerOnly = false
    @State private var backupStatusMessage = ""
    @State private var gameChangerStatusMessage = ""
    @FocusState private var isTeamNameFocused: Bool
    private let numberOfInningsDefaultsKey = "numberOfInnings"

    var body: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                List {
                Section {
                    TeamPickerView(viewModel: viewModel)

                    TextField("Team name", text: $editedTeamName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTeamNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            viewModel.updateSelectedTeamName(editedTeamName)
                            isTeamNameFocused = false
                        }

                    Button("Save Team Name") {
                        viewModel.updateSelectedTeamName(editedTeamName)
                        isTeamNameFocused = false
                    }
                }

                Section(header: settingsSectionHeader("Sport - \(viewModel.selectedSport.rawValue)")) {
                    Picker("Sport", selection: $viewModel.selectedSport) {
                        ForEach(SportType.allCases) { sport in
                            Image(systemName: iconName(for: sport))
                                .tag(sport)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Current sport selection only. Field, lineup, player positions, and sport-specific rules will be updated in later phases.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if viewModel.selectedSport == .baseballSoftball {
                    Section(header: settingsSectionHeader("Lineup Display")) {
                        Toggle("Show Ratings on Field", isOn: $viewModel.showRatingsOnField)
                        Toggle("Show Assigned Lineup Table", isOn: $viewModel.showAssignedLineupTable)
                        Toggle("Display First Name and Number", isOn: Binding(
                            get: { !viewModel.showFullNameAndNumber },
                            set: { viewModel.showFullNameAndNumber = !$0 }
                        ))
                        Toggle("Show Bench on Field Tab", isOn: $viewModel.showBenchOnField)

                        Stepper(
                            "Number of Innings: \(viewModel.numberOfInnings)",
                            value: $viewModel.numberOfInnings,
                            in: 1...12
                        )
                    }

                    Section(header: settingsSectionHeader("Batting Order")) {
                        Toggle("Only Show 9 Batters and a DH", isOn: $viewModel.showOnlyNineBattersAndDH)
                        Toggle("Warn when No Steal P/C Bats After No Steal Runner", isOn: $viewModel.showSlowSpeedBattingWarnings)
                    }

                    Section(header: settingsSectionHeader("Fall Ball")) {
                        Toggle("Fall Ball", isOn: $viewModel.fallBallEnabled)

                        if viewModel.fallBallEnabled {
                            Toggle("Youth", isOn: $viewModel.fallBallYouthEnabled)

                            Text("Fall Ball generates all 9 fielding innings randomly while trying to keep bench time balanced. Youth mode removes manual pitcher/catcher selection and randomly assigns every active player across every position.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SettingsDataSectionContentView(
                    viewModel: viewModel,
                    backupStatusMessage: $backupStatusMessage,
                    gameChangerStatusMessage: $gameChangerStatusMessage,
                    importPlayer: {
                        isImportingPlayerOnly = true
                        presentedSheet = .playerImport
                    },
                    importPlayerData: {
                        isImportingPlayerOnly = false
                        presentedSheet = .playerImport
                    },
                    importCoaches: {
                        presentedSheet = .coachImport
                    },
                    importGameChanger: {
                        presentedSheet = .gameChangerImport
                    },
                    sharePlayer: sharePlayer,
                    sharePlayerData: sharePlayerData,
                    shareCoaches: shareCoaches
                )

                Section(header: settingsSectionHeader("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version \(appVersion) (Build \(buildNumber))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Add players, give each player one or more positions, rate each position, manually set positions or auto-fill the rest of the field.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Legal")
                            .font(.headline)

                        Text("© 2026 Richard C. Morris Jr. All rights reserved.")
                            .font(.footnote)

                        Text("This application and its contents are proprietary. Unauthorized copying, distribution, modification, or reverse engineering is strictly prohibited.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("This app is provided \"as is\" without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Settings")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        viewModel.updateSelectedTeamName(editedTeamName)
                        isTeamNameFocused = false
                    }
                }
            }
            .onAppear {
                editedTeamName = viewModel.selectedTeamName

                let savedInnings = UserDefaults.standard.integer(forKey: numberOfInningsDefaultsKey)
                if (1...12).contains(savedInnings) {
                    viewModel.numberOfInnings = savedInnings
                } else {
                    viewModel.numberOfInnings = 7
                    UserDefaults.standard.set(7, forKey: numberOfInningsDefaultsKey)
                }
            }
            .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                editedTeamName = viewModel.selectedTeamName
                isTeamNameFocused = false
            }
            .onChange(of: viewModel.numberOfInnings) { _, newValue in
                let clampedValue = min(max(newValue, 1), 12)

                if clampedValue != newValue {
                    viewModel.numberOfInnings = clampedValue
                }

                UserDefaults.standard.set(clampedValue, forKey: numberOfInningsDefaultsKey)
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .playerImport:
                ImportDocumentPicker(
                    contentTypes: [.json, .data],
                    onPick: { url in
                        handlePlayerImport(url)
                    },
                    onCancel: {
                        backupStatusMessage = "Import cancelled."
                        presentedSheet = nil
                    }
                )

            case .coachImport:
                ImportDocumentPicker(
                    contentTypes: [.json, .data],
                    onPick: { url in
                        handleCoachImport(url)
                    },
                    onCancel: {
                        backupStatusMessage = "Coach import cancelled."
                        presentedSheet = nil
                    }
                )

            case .gameChangerImport:
                ImportDocumentPicker(
                    contentTypes: [.commaSeparatedText, .plainText, .data],
                    onPick: { url in
                        handleGameChangerImport(url)
                    },
                    onCancel: {
                        gameChangerStatusMessage = "Import cancelled."
                        presentedSheet = nil
                    }
                )

            case .share(let url):
                ActivityView(activityItems: [url])
            }
        }
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    private func presentShareSheet(url: URL) {
        presentedSheet = .share(url)
    }

    private func sharePlayer() {
        do {
            let data = viewModel.exportPlayerNameNumberData()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LineupChanger-Players.json")
            try data.write(to: url, options: .atomic)
            backupStatusMessage = "Player file ready to share."
            presentShareSheet(url: url)
        } catch {
            backupStatusMessage = "Share player failed: \(error.localizedDescription)"
        }
    }

    private func sharePlayerData() {
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

    private func shareCoaches() {
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

    private func handlePlayerImport(_ url: URL) {
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
        presentedSheet = nil
    }

    private func handleCoachImport(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            try viewModel.importCoachData(data)
            backupStatusMessage = "Coach import complete."
        } catch {
            backupStatusMessage = "Coach import failed: \(error.localizedDescription)"
        }
        presentedSheet = nil
    }

    private func handleGameChangerImport(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let matchedCount = try viewModel.importGameChangerStatsData(data)
            gameChangerStatusMessage = "Imported GameChanger stats for \(matchedCount) player(s)."
        } catch {
            gameChangerStatusMessage = "Import failed: \(error.localizedDescription)"
        }
        presentedSheet = nil
    }

    private func iconName(for sport: SportType) -> String {
        switch sport {
        case .baseballSoftball: return "baseball"
        case .basketball: return "basketball"
        case .football: return "football"
        case .volleyball: return "volleyball"
        case .soccer: return "soccerball"
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}

private enum SettingsPresentedSheet: Identifiable {
    case playerImport
    case coachImport
    case gameChangerImport
    case share(URL)

    var id: String {
        switch self {
        case .playerImport: return "playerImport"
        case .coachImport: return "coachImport"
        case .gameChangerImport: return "gameChangerImport"
        case .share(let url): return "share-\(url.lastPathComponent)"
        }
    }
}

struct SettingsDataSectionContentView: View {
    @ObservedObject var viewModel: LineupViewModel
    @Binding var backupStatusMessage: String
    @Binding var gameChangerStatusMessage: String

    let importPlayer: () -> Void
    let importPlayerData: () -> Void
    let importCoaches: () -> Void
    let importGameChanger: () -> Void
    let sharePlayer: () -> Void
    let sharePlayerData: () -> Void
    let shareCoaches: () -> Void

    @State private var selectedDataSection: SettingsDataSection = .player
    @State private var isShowingDeletePlayerDialog = false
    @State private var isShowingDeleteCoachDialog = false
    @State private var isShowingDeletePlayerDataConfirmation = false

    var body: some View {
        Section(header: settingsDataSectionHeader("Data")) {
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

    private func settingsDataSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
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

    private var gameChangerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                importGameChanger()
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
