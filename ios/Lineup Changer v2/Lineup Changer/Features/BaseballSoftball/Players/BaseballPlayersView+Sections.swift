// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballPlayersView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Baseball Players Sections
extension BaseballPlayersView {
    @ViewBuilder
    var playersListSections: some View {
        teamPickerSection
        coachesSection
        playersSection
    }

    private var teamPickerSection: some View {
        Section {
            TeamPickerView(viewModel: viewModel)
                .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                    focusedField = nil
                }
        }
    }

    private var coachesSection: some View {
        Section(header: playersSectionHeader("Coaches")) {
            addCoachRow

            if !viewModel.coaches.isEmpty {
                ForEach(sortedCoaches) { coach in
                    coachNavigationRow(for: coach)
                }
            }
        }
    }

    private var addCoachRow: some View {
        HStack {
            TextField("Coach name", text: $newCoachName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .newCoach)
                .submitLabel(.done)
                .onSubmit(addCoach)

            Button("Add") {
                addCoach()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func coachNavigationRow(for coach: Coach) -> some View {
        NavigationLink {
            CoachDetailView(viewModel: viewModel, coach: coach)
        } label: {
            CoachRowView(coach: coach)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                viewModel.deleteCoach(coachID: coach.id)
            }
        }
    }

    private var playersSection: some View {
        Section(header: playersSectionHeader("Players")) {
            addPlayerRow

            ForEach(sortedPlayers) { player in
                playerNavigationRow(for: player)
            }
            .onDelete(perform: viewModel.deletePlayers)
        }
    }

    private var addPlayerRow: some View {
        HStack {
            TextField("Player name", text: $newPlayerName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .newPlayer)
                .submitLabel(.done)
                .onSubmit(addPlayer)

            Button("Add") {
                addPlayer()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func playerNavigationRow(for player: Player) -> some View {
        NavigationLink {
            BaseballPlayerDetailView(viewModel: viewModel, player: player)
        } label: {
            BaseballPlayerRowView(player: player, viewModel: viewModel)
                .id("\(player.id)-\(player.status.rawValue)")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                viewModel.deletePlayer(playerID: player.id)
            }

            statusButtons(for: player)
        }
    }
}
