// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BasketballPlayersView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Basketball Players Sections
extension BasketballPlayersView {
    var basketballPlayersList: some View {
        List {
            teamPickerSection
            coachesSection
            playersSection
            statsInfoSection
            infoSection
        }
        .scrollContentBackground(.hidden)
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
        Section(header: basketballSectionHeader("Coaches")) {
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
        Section(header: basketballSectionHeader("Players")) {
            addPlayerRow
            gameChangerSortMenu
            playersListContent
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

    private var gameChangerSortMenu: some View {
        Menu {
            Button("Number") {
                gameChangerSortStat = nil
            }

            Divider()

            Button("PPG") {
                gameChangerSortStat = .ppg
            }

            Button("TOPG") {
                gameChangerSortStat = .topg
            }

            Button("RPG") {
                gameChangerSortStat = .rpg
            }

            Button("APG") {
                gameChangerSortStat = .apg
            }

            Button("SPG") {
                gameChangerSortStat = .spg
            }

            Button("BPG") {
                gameChangerSortStat = .bpg
            }

            Button("TS%") {
                gameChangerSortStat = .trueShootingPercentage
            }

            Button("AST/TO") {
                gameChangerSortStat = .assistTurnoverRatio
            }
        } label: {
            Label(
                gameChangerSortStat.map { "Sort by \($0.rawValue)" } ?? "Sort by GameChanger Stats",
                systemImage: "arrow.up.arrow.down.circle"
            )
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        }
    }

    @ViewBuilder
    private var playersListContent: some View {
        if viewModel.players.isEmpty {
            Text("No players added yet.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(sortedPlayers) { player in
                NavigationLink {
                    BasketballPlayerDetailView(viewModel: viewModel, player: player)
                } label: {
                    BasketballPlayerRowView(player: player, viewModel: viewModel)
                        .id("\(player.id)-\(player.name)-\(player.number)-\(player.status.rawValue)-\(PlayerDisplayHelper.basketballPositionSummaryValue(for: player))")
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        viewModel.deletePlayer(playerID: player.id)
                    }

                    statusButtons(for: player)
                }
            }
            .onDelete(perform: viewModel.deletePlayers)
        }
    }

    private var infoSection: some View {
        Section(header: basketballSectionHeader("How this works")) {
            Text("Basketball players and coaches use team rosters, contact tools, notes, availability, and position ratings. Rotation tools will be added in the basketball lineup phase.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var statsInfoSection: some View {
        Section(header: basketballSectionHeader("Stats")) {
            Text("PPG = Points per game\nTOPG = Turnovers per game\nRPG = Rebounds per game\nAPG = Assists per game\nSPG = Steals per game\nBPG = Blocks per game\nTS% = True shooting percentage\nAST/TO = Assist to turnover ratio")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
