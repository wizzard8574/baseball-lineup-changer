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
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    TeamPickerView(viewModel: viewModel)
                }
                .padding(.horizontal)
                .onChange(of: viewModel.selectedTeamIndex) { _, _ in
                    focusedField = nil
                }

                List {
                    Section("Coaches") {
                        HStack {
                            TextField("Coach name", text: $newCoachName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .newCoach)
                                .submitLabel(.done)
                                .onSubmit {
                                    viewModel.addCoach(name: newCoachName)
                                    newCoachName = ""
                                    focusedField = nil
                                }

                            Button("Add") {
                                viewModel.addCoach(name: newCoachName)
                                newCoachName = ""
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if !viewModel.coaches.isEmpty {
                            ForEach(viewModel.coaches.sorted { lhs, rhs in
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
                            }) { coach in
                                NavigationLink {
                                    CoachDetailView(viewModel: viewModel, coach: coach)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Text(coach.name)
                                                .font(.headline)

                                            if !coach.role.isEmpty {
                                                Text("- \(coach.role)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        let contactLine = [
                                            coach.number.isEmpty ? nil : "#\(coach.number)",
                                            coach.cell.isEmpty ? nil : coach.cell
                                        ].compactMap { $0 }.joined(separator: " • ")

                                        if !contactLine.isEmpty {
                                            Text(contactLine)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteCoach(coachID: coach.id)
                                    }
                                }
                            }
                        }
                    }

                    Section("Players") {
                        HStack {
                            TextField("Player name", text: $newPlayerName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .newPlayer)
                                .submitLabel(.done)
                                .onSubmit {
                                    viewModel.addPlayer(name: newPlayerName)
                                    newPlayerName = ""
                                    focusedField = nil
                                }

                            Button("Add") {
                                viewModel.addPlayer(name: newPlayerName)
                                newPlayerName = ""
                                focusedField = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        ForEach(viewModel.players.sorted { lhs, rhs in
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
                    }) { player in
                        NavigationLink {
                            PlayerDetailView(viewModel: viewModel, player: player)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text(viewModel.displayLabel(for: player))
                                        .font(.headline)
                                    if player.status == .guest {
                                        Text("(Guest)")
                                            .font(.headline)
                                            .italic()
                                            .foregroundStyle(.red)
                                    }
                                }
                                
                                PhoneContactMenu(number: player.cell)
                                    .font(.caption)
                                
                                if player.status != .active && player.status != .guest {
                                    Text(player.status == .injured ? "Injured" : "Unavailable")
                                        .font(.caption)
                                        .foregroundStyle(player.status == .injured ? .red : .orange)
                                }

                                if player.positionRatings.isEmpty {
                                    Text("No positions added")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(positionSummary(for: player))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                viewModel.deletePlayer(playerID: player.id)
                            }

                            Button("Injured") {
                                viewModel.setPlayerStatus(playerID: player.id, status: .injured)
                            }
                            .tint(.red)

                            Button("Unavailable") {
                                viewModel.setPlayerStatus(playerID: player.id, status: .unavailable)
                            }
                            .tint(.red)

                            Button("Guest") {
                                viewModel.setPlayerStatus(playerID: player.id, status: .guest)
                            }
                            .tint(.red)

                            if player.status != .active {
                                Button("Active") {
                                    viewModel.setPlayerStatus(playerID: player.id, status: .active)
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deletePlayers)
                    }
                }
            }
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
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

    private func positionSummary(for player: Player) -> String {
        FieldPosition.allCases
            .compactMap { position in
                guard let rating = player.positionRatings[position] else { return nil }
                return "\(position.rawValue): \(rating)"
            }
            .joined(separator: " • ")
    }
}


