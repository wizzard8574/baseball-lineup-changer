// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView.swift
//
//
//
// BaseballPlayersView contains the baseball/softball Players tab UI.
// It manages coach creation, player creation, roster navigation, and status actions.
import SwiftUI

// MARK: - Baseball / Softball Players View
// Full roster management layout for baseball/softball.
struct BaseballPlayersView: View {
    // Shared roster, coach, team, and sport state.
    @ObservedObject var viewModel: LineupViewModel
    // Draft text for the add-player and add-coach fields.
    @State var newPlayerName = ""
    @State var newCoachName = ""
    // Newly created records are assigned here to push directly into detail screens.
    @State var newPlayerDraft: Player?
    @State var newCoachDraft: Coach?
    // Tracks keyboard focus for the add-player and add-coach text fields.
    @FocusState var focusedField: PlayerListFocusedField?

    // MARK: - Focus Fields
    // Identifies which add field currently owns keyboard focus.
    enum PlayerListFocusedField {
        case newPlayer
        case newCoach
    }

    // MARK: - Body
    var body: some View {
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
                                .onSubmit(addCoach)

                            // Add button mirrors the return-key submit behavior.
                            Button("Add") {
                                addCoach()
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
                                .onSubmit(addPlayer)

                            // Add button mirrors the return-key submit behavior.
                            Button("Add") {
                                addPlayer()
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
                                BaseballPlayerRowView(player: player, viewModel: viewModel)
                                    .id("\(player.id)-\(player.status.rawValue)")
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Swipe action removes the player and related lineup references.
                                Button("Delete", role: .destructive) {
                                    viewModel.deletePlayer(playerID: player.id)
                                }

                                statusButtons(for: player)
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
                    playersTitle
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

    
}
