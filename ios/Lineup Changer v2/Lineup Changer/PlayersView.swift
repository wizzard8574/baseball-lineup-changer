// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayersView.swift
//
//
//
// PlayersView.swift contains the Players tab UI.
// It manages team selection, coach creation, player creation, roster navigation,
// swipe status actions, and the sport-specific placeholder screen.
import SwiftUI
import Foundation

// MARK: - Team Picker View

// Segmented picker for switching between the app's two team slots.
struct TeamPickerView: View {
    // Shared app state containing selected team and team names.
    @ObservedObject var viewModel: LineupViewModel

    // Picker selection writes through to selectTeam so team snapshots are saved/restored.
    var body: some View {
        Picker("Team", selection: Binding(
            get: { viewModel.selectedTeamIndex },
            set: { viewModel.selectTeam($0) }
        )) {
            // Fallback labels protect against malformed saved teamNames arrays.
            Text(viewModel.teamNames.indices.contains(0) ? viewModel.teamNames[0] : "Team 1").tag(0)
            Text(viewModel.teamNames.indices.contains(1) ? viewModel.teamNames[1] : "Team 2").tag(1)
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Team Header View
// Team picker plus editable team-name field used where a full team header is needed.
struct TeamHeaderView: View {
    // Shared app state for team selection and team name updates.
    @ObservedObject var viewModel: LineupViewModel
    // Local editable team-name text owned by the parent view.
    @Binding var editedTeamName: String

    // Saves team name changes on submit or button tap.
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Team selector at the top of the header.
            TeamPickerView(viewModel: viewModel)

            // Editable team name field.
            TextField("Team name", text: $editedTeamName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.updateSelectedTeamName(editedTeamName)
                }

            // Explicit save button for users who do not submit from the keyboard.
            Button("Save Team Name") {
                viewModel.updateSelectedTeamName(editedTeamName)
            }
            .buttonStyle(.bordered)
        }
        // Refresh the edit field when switching between team slots.
        .onChange(of: viewModel.selectedTeamIndex) { _, _ in
            editedTeamName = viewModel.selectedTeamName
        }
    }
}

// MARK: - Player List View
// Main Players tab screen for baseball/softball.
// Coaches and players can be added, opened for detail editing, deleted, and updated by status.
struct PlayerListView: View {
    // Shared roster, coach, team, and sport state.
    @ObservedObject var viewModel: LineupViewModel
    // Draft text for the add-player and add-coach fields.
    @State private var newPlayerName = ""
    @State private var newCoachName = ""
    // Newly created records are assigned here to push directly into detail screens.
    @State private var newPlayerDraft: Player?
    @State private var newCoachDraft: Coach?
    // Tracks keyboard focus for the add-player and add-coach text fields.
    @FocusState private var focusedField: PlayerListFocusedField?

    // MARK: - Focus Fields
    // Identifies which add field currently owns keyboard focus.
    private enum PlayerListFocusedField {
        case newPlayer
        case newCoach
    }

    // MARK: - Body
    // Shows the baseball/softball roster UI or a placeholder for unsupported sports.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            baseballView
        default:
            comingSoonView
        }
    }

    // MARK: - Baseball / Softball Layout
    // Full roster management layout for baseball/softball.
    private var baseballView: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed app background.
                AppSportsBackground()

                List {
                    // Team picker section.
                    Section {
                        TeamPickerView(viewModel: viewModel)
                            .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                                // Dismiss add-field focus when changing teams.
                                focusedField = nil
                            }
                    }
                    // Coach creation and coach list section.
                    Section(header: playersSectionHeader("Coaches")) {
                        HStack {
                            // New coach name entry field.
                            TextField("Coach name", text: $newCoachName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .newCoach)
                                .submitLabel(.done)
                                .onSubmit {
                                    // Trim and validate before creating the coach.
                                    let trimmedName = newCoachName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmedName.isEmpty else { return }

                                    // Open the newly created coach detail screen immediately.
                                    if let coach = viewModel.addCoach(name: trimmedName) {
                                        newCoachDraft = coach
                                    }
                                    newCoachName = ""
                                    focusedField = nil
                                }

                            // Add button mirrors the return-key submit behavior.
                            Button("Add") {
                                // Trim and validate before creating the coach.
                                let trimmedName = newCoachName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedName.isEmpty else { return }

                                // Open the newly created coach detail screen immediately.
                                if let coach = viewModel.addCoach(name: trimmedName) {
                                    newCoachDraft = coach
                                }
                                newCoachName = ""
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        // Only render coach rows when coaches exist.
                        if !viewModel.coaches.isEmpty {
                            // Coaches are sorted with Head Coach first, then by number/name.
                            ForEach(sortedCoaches) { coach in
                                NavigationLink {
                                    // Detail view edits coach profile and contact info.
                                    CoachDetailView(viewModel: viewModel, coach: coach)
                                } label: {
                                    CoachRowView(coach: coach)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Swipe action removes this coach from the current team.
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteCoach(coachID: coach.id)
                                    }
                                }
                            }
                        }
                    }

                    // Player creation and roster list section.
                    Section(header: playersSectionHeader("Players")) {
                        HStack {
                            // New player name entry field.
                            TextField("Player name", text: $newPlayerName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .newPlayer)
                                .submitLabel(.done)
                                .onSubmit {
                                    // Trim and validate before creating the player.
                                    let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmedName.isEmpty else { return }

                                    // Open the newly created player detail screen immediately.
                                    if let player = viewModel.addPlayer(name: trimmedName) {
                                        newPlayerDraft = player
                                    }
                                    newPlayerName = ""
                                    focusedField = nil
                                }

                            // Add button mirrors the return-key submit behavior.
                            Button("Add") {
                                // Trim and validate before creating the player.
                                let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedName.isEmpty else { return }

                                // Open the newly created player detail screen immediately.
                                if let player = viewModel.addPlayer(name: trimmedName) {
                                    newPlayerDraft = player
                                }
                                newPlayerName = ""
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        // Roster rows sorted by status, number, and name.
                        ForEach(sortedPlayers) { player in
                            NavigationLink {
                                // Detail view edits player profile, ratings, status, and notes.
                                PlayerDetailView(viewModel: viewModel, player: player)
                            } label: {
                                // Row reflects status changes by including status in its identity.
                                PlayerRowView(player: player, viewModel: viewModel)
                                    .id("\(player.id)-\(player.status.rawValue)")
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Swipe action removes the player and related lineup references.
                                Button("Delete", role: .destructive) {
                                    viewModel.deletePlayer(playerID: player.id)
                                }

                                // Status shortcuts hide the action matching the current status.
                                if player.status != .unavailable {
                                    Button("Unavailable") {
                                        viewModel.setPlayerStatus(playerID: player.id, status: .unavailable)
                                    }
                                    .tint(.orange)
                                }

                                if player.status != .injured {
                                    Button("Injured") {
                                        viewModel.setPlayerStatus(playerID: player.id, status: .injured)
                                    }
                                    .tint(.red)
                                }

                                if player.status != .guest {
                                    Button("Guest") {
                                        viewModel.setPlayerStatus(playerID: player.id, status: .guest)
                                    }
                                    .tint(.blue)
                                }

                                if player.status != .active {
                                    Button("Active") {
                                        viewModel.setPlayerStatus(playerID: player.id, status: .active)
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                    // Supports Edit-mode list deletion.
                    .onDelete(perform: viewModel.deletePlayers)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        // Decorative players icon used in the custom navigation title.
                        Image(systemName: "person.3.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Players")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }

                // Edit button enables list deletion/reordering-style controls.
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            // Push directly to the detail screen after adding a player.
            .navigationDestination(item: $newPlayerDraft) { player in
                PlayerDetailView(viewModel: viewModel, player: player)
            }
            // Push directly to the detail screen after adding a coach.
            .navigationDestination(item: $newCoachDraft) { coach in
                CoachDetailView(viewModel: viewModel, coach: coach)
            }
        }
    }

    // MARK: - Sorting Helpers
    // Coaches sort with Head Coach first, then by numeric number, then by name.
    private var sortedCoaches: [Coach] {
        viewModel.coaches.sorted { lhs, rhs in
            // Keep the Head Coach at the top of the coach list.
            let lhsIsHeadCoach = lhs.role == "Head Coach"
            let rhsIsHeadCoach = rhs.role == "Head Coach"

            if lhsIsHeadCoach != rhsIsHeadCoach {
                return lhsIsHeadCoach
            }

            // Use numeric ordering when both coach numbers are valid numbers.
            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)

            // Numeric numbers sort before blank or nonnumeric numbers.
            switch (lhsNumber, rhsNumber) {
            case let (l?, r?):
                return l < r
            case (nil, nil):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            }
        }
    }

    // Players sort by status first, then numeric number, then name.
    private var sortedPlayers: [Player] {
        viewModel.players.sorted { lhs, rhs in
            // Guest players are pushed below regular roster players.
            if lhs.status == .guest && rhs.status != .guest { return false }
            if rhs.status == .guest && lhs.status != .guest { return true }

            // Use numeric ordering when both player numbers are valid numbers.
            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)

            // Numeric numbers sort before blank or nonnumeric numbers.
            switch (lhsNumber, rhsNumber) {
            case let (l?, r?):
                return l < r
            case (nil, nil):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            }
        }
    }

    // MARK: - Section Header Styling
    // Shared styling helper for roster section headers.
    private func playersSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    // MARK: - Coming Soon Placeholder
    // Placeholder screen shown for sports whose roster features are not yet implemented.
    private var comingSoonView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.3")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("\(viewModel.selectedSport.rawValue) Players Coming Soon")
                    .font(.headline)

                Text("Player setup for this sport will be available in a future update.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Players")
        }
    }

}
