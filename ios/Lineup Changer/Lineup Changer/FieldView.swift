//
//  FieldView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import SwiftUI

// MARK: - Baseball Field View

// MARK: - Lineup Tab

struct AssignmentView: View {
    @ObservedObject var viewModel: LineupViewModel

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
            Form {
                Section("Team - \(viewModel.selectedTeamName)") {
                    TeamPickerView(viewModel: viewModel)
                }
                Section("Inning - \(viewModel.selectedInning)") {
                    Picker("Inning", selection: Binding(
                        get: { viewModel.selectedInning },
                        set: { viewModel.selectInning($0) }
                    )) {
                        ForEach(1...9, id: \.self) { inning in
                            Text("\(inning)").tag(inning)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !viewModel.fallBallYouthEnabled {
                    Section("Manual Positions") {
                        if !viewModel.fallBallEnabled {
                            Picker("Pitcher", selection: Binding(
                                get: { viewModel.pitcherID },
                                set: { newValue in
                                    viewModel.updatePitcher(newValue)
                                }
                            )) {
                                Text("Choose pitcher").tag(UUID?.none)
                                ForEach(viewModel.activePlayers) { player in
                                    Text(player.name).tag(Optional(player.id))
                                }
                            }
                        }

                        Picker("Catcher", selection: Binding(
                            get: { viewModel.catcherID },
                            set: { newValue in
                                viewModel.updateCatcher(newValue)
                            }
                        )) {
                            Text("Choose catcher").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(player.name).tag(Optional(player.id))
                            }
                        }
                    }
                }

                Section("Lineup Actions") {
                    VStack(spacing: 10) {
                        Button {
                            viewModel.assignLineup()
                        } label: {
                            Label(viewModel.fallBallEnabled ? "Generate Fall Ball Lineups" : "Auto-Fill Positions", systemImage: "sparkles")
                                .labelStyle(.titleOnly)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            viewModel.setCurrentLineupForAllInnings()
                        } label: {
                            Label("Use This Lineup for All Innings", systemImage: "square.stack.3d.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        HStack(spacing: 10) {
                            Button(role: .destructive) {
                                viewModel.clearInning()
                            } label: {
                                Label("Clear Inning", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                viewModel.clearAllInnings()
                            } label: {
                                Label("Clear All", systemImage: "trash.slash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .controlSize(.regular)
                    }
                    .buttonStyle(.borderless)
                    .padding(.vertical, 4)
                }

                Section("Field View") {
                    BaseballFieldLineupView(
                        lineup: viewModel.lineup,
                        showRatings: viewModel.showRatingsOnField,
                        showFullNameAndNumber: viewModel.showFullNameAndNumber
                    )
                    .frame(height: 430)
                    .listRowInsets(EdgeInsets())
                }

                if viewModel.showAssignedLineupTable {
                    Section("Assigned Lineup") {
                        ForEach(FieldPosition.allCases) { position in
                            HStack {
                                Text(position.rawValue)
                                    .fontWeight(.semibold)
                                    .frame(width: 50, alignment: .leading)

                                Picker("", selection: Binding(
                                    get: { viewModel.lineup[position]?.id },
                                    set: { newPlayerID in
                                        viewModel.updateFieldPosition(position, playerID: newPlayerID)
                                    }
                                )) {
                                    Text("Unassigned").tag(UUID?.none)
                                    ForEach(viewModel.activePlayers) { player in
                                        Text(viewModel.displayLabel(for: player)).tag(Optional(player.id))
                                    }
                                }
                                .pickerStyle(.menu)

                                Spacer()

                                if let player = viewModel.lineup[position] {
                                    Text(ratingLabel(for: player, at: position))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if viewModel.showBenchOnField {
                    Section("Bench") {
                        let bench = benchPlayers()

                        if bench.isEmpty {
                            Text("No bench players")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(bench) { player in
                                HStack {
                                    HStack(spacing: 4) {
                                        Text(viewModel.displayLabel(for: player))
                                        if player.status == .guest {
                                            Text("(Guest)")
                                                .italic()
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    Spacer()

                                    Button("Put In Field") {
                                        viewModel.placeBenchPlayerInField(playerID: player.id)
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Menu("Position") {
                                        ForEach(FieldPosition.autoAssignedPositions) { position in
                                            Button("Move to \(position.rawValue)") {
                                                viewModel.updateFieldPosition(position, playerID: player.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section("How assignment works") {
                    Text(viewModel.fallBallEnabled ? "Fall Ball generates all 9 innings at once and tries to share bench time evenly. Standard Fall Ball automatically uses a different pitcher each inning from players who have Pitcher listed on their profile, keeps catcher manual, then randomly assigns players only to positions listed on their profile. Youth mode randomly assigns all active players across every position, including pitcher and catcher." : "Each inning can have a different field lineup. When you set an inning, the app carries that lineup forward to later empty innings until you manually change or auto-fill those innings. Pitcher and catcher are selected manually. The app fills 1B, 2B, 3B, SS, LF, CF, and RF using the best available rating.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Field")
        }
    }

    private var comingSoonView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sportscourt")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("\(viewModel.selectedSport.rawValue) Coming Soon")
                    .font(.headline)

                Text("Field and lineup features for this sport will be available in a future update.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Field")
        }
    }

    private func benchPlayers() -> [Player] {
        let assignedIDs = Set(viewModel.lineup.values.map { $0.id })
        return viewModel.activePlayers.filter { !assignedIDs.contains($0.id) }
    }

    private func displayName(for position: FieldPosition) -> String {
        switch position {
        case .pitcher: return "Pitcher (P)"
        case .catcher: return "Catcher (C)"
        case .firstBase: return "First Base (1B)"
        case .secondBase: return "Second Base (2B)"
        case .thirdBase: return "Third Base (3B)"
        case .shortstop: return "Shortstop (SS)"
        case .leftField: return "Left Field (LF)"
        case .centerField: return "Center Field (CF)"
        case .rightField: return "Right Field (RF)"
        }
    }

    private func ratingLabel(for player: Player, at position: FieldPosition) -> String {
        guard let rating = player.positionRatings[position] else { return "Manual" }
        return "Rating \(rating)"
    }
}
