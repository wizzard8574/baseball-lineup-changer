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

// MARK: - Settings Data Section
// Segmented-control options for the import/export data tools.
private enum SettingsDataSection: String, CaseIterable, Identifiable {
    // Lightweight player sharing: name, number, and cell.
    case player = "Player"
    // Full player-related app-state backup.
    case playerData = "Player Data"
    // Coach-only import/export tools.
    case coaches = "Coaches"
    // GameChanger CSV stat import and cleanup tools.
    case gameChanger = "GameChanger"

    // Allows SettingsDataSection to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }

    // Short labels used by the segmented picker.
    var pickerTitle: String {
        switch self {
        case .player: return "Player"
        case .playerData: return "Player Data"
        case .coaches: return "Coaches"
        case .gameChanger: return "GC Stats"
        }
    }
}

// MARK: - Settings View
// Main Settings tab screen.
struct SettingsView: View {
    // Shared app state containing settings, team names, import/export methods, and sport state.
    @ObservedObject var viewModel: LineupViewModel
    // Local editable team name so text-field edits can be saved intentionally.
    @State private var editedTeamName = ""
    // Controls document picker and share-sheet presentation.
    @State private var presentedSheet: SettingsPresentedSheet?
    // Distinguishes lightweight player imports from full player-data imports.
    @State private var isImportingPlayerOnly = false
    // User-facing status messages for backup/import/export actions.
    @State private var backupStatusMessage = ""
    @State private var gameChangerStatusMessage = ""
    // Tracks keyboard focus for the editable team-name field.
    @FocusState private var isTeamNameFocused: Bool
    // Changes whenever active sport/team labels change so stale segmented controls are discarded.
    private var teamEditorIdentity: String {
        "\(viewModel.selectedSport.rawValue)-\(viewModel.selectedTeamIndex)-\(viewModel.teamNames.joined(separator: "|"))"
    }

    // MARK: - Body
    // Main settings layout with team, sport, baseball options, data tools, and app info.
    var body: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed app background.
                AppSportsBackground()

                List {
                // Team selection and team name editing section.
                Section {
                    // Switches between the two saved team slots.
                    TeamPickerView(viewModel: viewModel)

                    // Editable team name field.
                    TextField("Team name", text: $editedTeamName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTeamNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            // Save team name when the keyboard submit button is pressed.
                            viewModel.updateSelectedTeamName(editedTeamName)
                            isTeamNameFocused = false
                        }

                    // Explicit save button for team-name changes.
                    Button("Save Team Name") {
                        viewModel.updateSelectedTeamName(editedTeamName)
                        isTeamNameFocused = false
                    }
                }
                .id(teamEditorIdentity)

                // Sport selector. Baseball/softball is currently the fully supported mode.
                Section(header: settingsSectionHeader("Sport - \(viewModel.selectedSport.rawValue)")) {
                    // Icon-only segmented picker for sport modes.
                    Picker("Sport", selection: Binding(
                        get: { viewModel.selectedSport },
                        set: { sport in
                            viewModel.selectSport(sport)
                            editedTeamName = viewModel.selectedTeamName
                            isTeamNameFocused = false
                        }
                    )) {
                        ForEach(SportType.allCases) { sport in
                            Image(systemName: iconName(for: sport))
                                .tag(sport)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Clarifies that non-baseball sports are placeholders for now.
                    Text("Current sport selection only. Field, lineup, player positions, and sport-specific rules will be updated in later phases.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Baseball/softball-specific settings are hidden for placeholder sports.
                if viewModel.selectedSport == .baseballSoftball {
                    // Field and lineup display preferences.
                    Section(header: settingsSectionHeader("Lineup Display")) {
                        Toggle("Show Ratings on Field", isOn: $viewModel.showRatingsOnField)
                        Toggle("Show Assigned Lineup Table", isOn: $viewModel.showAssignedLineupTable)
                        Toggle("Display First Name and Number", isOn: Binding(
                            get: { !viewModel.showFullNameAndNumber },
                            set: { viewModel.showFullNameAndNumber = !$0 }
                        ))
                        Toggle("Show Bench on Field Tab", isOn: $viewModel.showBenchOnField)

                        // Inning count is clamped to the supported 1...12 range elsewhere as well.
                        Stepper(
                            "Number of Innings: \(viewModel.numberOfInnings)",
                            value: $viewModel.numberOfInnings,
                            in: 1...12
                        )
                    }

                    // Batting order display and warning preferences.
                    Section(header: settingsSectionHeader("Batting Order")) {
                        Toggle("Only Show 9 Batters and a DH", isOn: $viewModel.showOnlyNineBattersAndDH)
                        Toggle("Warn when No Steal P/C Bats After No Steal Runner", isOn: $viewModel.showSlowSpeedBattingWarnings)
                    }

                    // Fall Ball generation settings.
                    Section(header: settingsSectionHeader("Fall Ball")) {
                        Toggle("Fall Ball", isOn: $viewModel.fallBallEnabled)

                        // Youth mode is only available when Fall Ball is enabled.
                        if viewModel.fallBallEnabled {
                            Toggle("Youth", isOn: $viewModel.fallBallYouthEnabled)

                            Text("Fall Ball generates all 9 fielding innings randomly while trying to keep bench time balanced. Youth mode removes manual pitcher/catcher selection and randomly assigns every active player across every position.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Import/export, delete, and GameChanger data tools.
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

                // App version, usage summary, and legal information.
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
                        // Decorative settings icon used in the custom navigation title.
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
                // Keep the edit field in sync with the selected team.
                editedTeamName = viewModel.selectedTeamName

                // Clamp any restored inning count to the supported range.
                viewModel.numberOfInnings = min(max(viewModel.numberOfInnings, 1), 12)
            }
            // Refresh the team-name field when switching teams.
            .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                editedTeamName = viewModel.selectedTeamName
                isTeamNameFocused = false
            }
            // Refresh the edit field when sport changes replace the active team slots.
            .onChange(of: viewModel.teamNames) { _, _ in
                editedTeamName = viewModel.selectedTeamName
                isTeamNameFocused = false
            }
            // Segmented pickers can redraw before the local text field sees the new sport state.
            .onChange(of: viewModel.selectedSport) { _, _ in
                editedTeamName = viewModel.selectedTeamName
                isTeamNameFocused = false
            }
            // Keep inning count valid and persisted when changed by the Stepper.
            .onChange(of: viewModel.numberOfInnings) { _, newValue in
                // Clamp manually set values into the supported range.
                let clampedValue = min(max(newValue, 1), 12)

                if clampedValue != newValue {
                    viewModel.numberOfInnings = clampedValue
                }
            }
        }
        // Presents document pickers and share sheets for Settings workflows.
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            // Player import sheet handles both lightweight and full player-data imports.
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
            // Coach import sheet.
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
            // GameChanger CSV import sheet.
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
            // Native iOS share sheet for generated export files.
            case .share(let url):
                ActivityView(activityItems: [url])
            }
        }
    }

    // MARK: - Section Header Styling
    // Shared styling helper for Settings section headers.
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

    // MARK: - Share Helpers
    // Presents the native share sheet for an export file URL.
    private func presentShareSheet(url: URL) {
        presentedSheet = .share(url)
    }

    // Exports and shares the lightweight player file.
    private func sharePlayer() {
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

    // Exports and shares the coach-only file.
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

    // MARK: - Import Handlers
    // Imports either lightweight player data or full player-data backup depending on current mode.
    private func handlePlayerImport(_ url: URL) {
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

    // Imports GameChanger CSV stats and reports how many players were matched.
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

    // MARK: - Display Helpers
    // Returns the SF Symbol name used for each sport in the segmented picker.
    private func iconName(for sport: SportType) -> String {
        switch sport {
        case .baseballSoftball: return "baseball"
        case .basketball: return "basketball"
        case .football: return "football"
        case .volleyball: return "volleyball"
        case .soccer: return "soccerball"
        }
    }

    // Reads the marketing version from the app bundle.
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    // Reads the build number from the app bundle.
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}

// MARK: - Settings Presented Sheet
// Sheet routes used by SettingsView.
private enum SettingsPresentedSheet: Identifiable {
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
    @State private var selectedDataSection: SettingsDataSection = .player
    @State private var isShowingDeletePlayerDialog = false
    @State private var isShowingDeleteCoachDialog = false
    @State private var isShowingDeletePlayerDataConfirmation = false

    // MARK: - Body
    // Shows the selected data-management tools and related confirmation dialogs.
    var body: some View {
        Section(header: settingsDataSectionHeader("Data")) {
            // Switch between player, full data, coach, and GameChanger tools.
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

            // Renders the selected data-management subsection.
            selectedDataSectionView

            // Show backup/import/export feedback when available.
            if !backupStatusMessage.isEmpty {
                Label(backupStatusMessage, systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        // Player deletion confirmation listing individual players.
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
        // Coach deletion confirmation listing individual coaches.
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
        // Bulk player-data deletion confirmation.
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

    // MARK: - Section Header Styling
    // Shared styling helper for the data section header.
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

    // MARK: - Section Routing
    // Erases the selected subsection to AnyView so a switch can choose different layouts.
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

    // MARK: - Player Tools
    // Lightweight player import/share/delete tools.
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
    // Full player-data import/share/delete tools.
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
    // Coach-only import/share/delete tools.
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
    // GameChanger CSV import and stat cleanup tools.
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

            // Show GameChanger import/cleanup feedback separately from backup messages.
            if !gameChangerStatusMessage.isEmpty {
                Label(gameChangerStatusMessage, systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }

}
