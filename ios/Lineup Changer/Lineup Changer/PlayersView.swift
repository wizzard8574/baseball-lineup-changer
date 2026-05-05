//
//  PlayersView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import SwiftUI
import Foundation

// MARK: - Players Tab

struct TeamPickerView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
        Picker("Team", selection: Binding(
            get: { viewModel.selectedTeamIndex },
            set: { viewModel.selectTeam($0) }
        )) {
            Text(viewModel.teamNames.indices.contains(0) ? viewModel.teamNames[0] : "Team 1").tag(0)
            Text(viewModel.teamNames.indices.contains(1) ? viewModel.teamNames[1] : "Team 2").tag(1)
        }
        .pickerStyle(.segmented)
    }
}

struct TeamHeaderView: View {
    @ObservedObject var viewModel: LineupViewModel
    @Binding var editedTeamName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TeamPickerView(viewModel: viewModel)

            TextField("Team name", text: $editedTeamName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.updateSelectedTeamName(editedTeamName)
                }

            Button("Save Team Name") {
                viewModel.updateSelectedTeamName(editedTeamName)
            }
            .buttonStyle(.bordered)
        }
        .onChange(of: viewModel.selectedTeamIndex) { _, _ in
            editedTeamName = viewModel.selectedTeamName
        }
    }
}

struct PlayerListView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State private var newPlayerName = ""
    @State private var newCoachName = ""
    @State private var newPlayerDraft: Player?
    @State private var newCoachDraft: Coach?
    @FocusState private var focusedField: PlayerListFocusedField?

    private enum PlayerListFocusedField {
        case newPlayer
        case newCoach
    }

    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            baseballView
        default:
            comingSoonView
        }
    }

    private var baseballView: some View {
        NavigationStack {
            ZStack {
                AppSportsBackground()

                List {
                    Section {
                        TeamPickerView(viewModel: viewModel)
                            .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                                focusedField = nil
                            }
                    }
                    Section(header: playersSectionHeader("Coaches")) {
                        HStack {
                            TextField("Coach name", text: $newCoachName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .newCoach)
                                .submitLabel(.done)
                                .onSubmit {
                                    let trimmedName = newCoachName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmedName.isEmpty else { return }

                                    if let coach = viewModel.addCoach(name: trimmedName) {
                                        newCoachDraft = coach
                                    }
                                    newCoachName = ""
                                    focusedField = nil
                                }

                            Button("Add") {
                                let trimmedName = newCoachName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedName.isEmpty else { return }

                                if let coach = viewModel.addCoach(name: trimmedName) {
                                    newCoachDraft = coach
                                }
                                newCoachName = ""
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if !viewModel.coaches.isEmpty {
                            ForEach(sortedCoaches) { coach in
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
                        }
                    }

                    Section(header: playersSectionHeader("Players")) {
                        HStack {
                            TextField("Player name", text: $newPlayerName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .newPlayer)
                                .submitLabel(.done)
                                .onSubmit {
                                    let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmedName.isEmpty else { return }

                                    if let player = viewModel.addPlayer(name: trimmedName) {
                                        newPlayerDraft = player
                                    }
                                    newPlayerName = ""
                                    focusedField = nil
                                }

                            Button("Add") {
                                let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedName.isEmpty else { return }

                                if let player = viewModel.addPlayer(name: trimmedName) {
                                    newPlayerDraft = player
                                }
                                newPlayerName = ""
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        ForEach(sortedPlayers) { player in
                            NavigationLink {
                                PlayerDetailView(viewModel: viewModel, player: player)
                            } label: {
                                PlayerRowView(player: player, viewModel: viewModel)
                                    .id("\(player.id)-\(player.status.rawValue)")
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    viewModel.deletePlayer(playerID: player.id)
                                }

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
                    .onDelete(perform: viewModel.deletePlayers)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
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

                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .navigationDestination(item: $newPlayerDraft) { player in
                PlayerDetailView(viewModel: viewModel, player: player)
            }
            .navigationDestination(item: $newCoachDraft) { coach in
                CoachDetailView(viewModel: viewModel, coach: coach)
            }
        }
    }

    private var sortedCoaches: [Coach] {
        viewModel.coaches.sorted { lhs, rhs in
            let lhsIsHeadCoach = lhs.role == "Head Coach"
            let rhsIsHeadCoach = rhs.role == "Head Coach"

            if lhsIsHeadCoach != rhsIsHeadCoach {
                return lhsIsHeadCoach
            }

            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)

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

    private var sortedPlayers: [Player] {
        viewModel.players.sorted { lhs, rhs in
            // Guest sorting logic
            if lhs.status == .guest && rhs.status != .guest { return false }
            if rhs.status == .guest && lhs.status != .guest { return true }

            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)

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
