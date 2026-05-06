//
//  LineupView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import SwiftUI

// MARK: - Lineup / Batting Order Tab

struct LineupOrderView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State private var isShowingLineupShareSheet = false
    @State private var lineupPDFURL: URL?
    @State private var scorebookPDFURL: URL?
    @State private var lineupExportMessage = ""

    private var orderedPlayers: [Player] {
        viewModel.battingOrderIDs
            .compactMap { viewModel.player(for: $0) }
            .filter { $0.status == .active }
    }

    private var displayedBatters: [Player] {
        if viewModel.showOnlyNineBattersAndDH {
            return Array(orderedPlayers.prefix(9))
        }

        return orderedPlayers
    }

    private func hasSlowPitcherCatcherWarning(at index: Int) -> Bool {
        guard viewModel.showSlowSpeedBattingWarnings,
              index > 0,
              displayedBatters.indices.contains(index),
              displayedBatters.indices.contains(index - 1) else { return false }

        let currentPlayer = displayedBatters[index]
        let previousPlayer = displayedBatters[index - 1]
        let isPitcherOrCatcher = currentPlayer.id == viewModel.pitcherID || currentPlayer.id == viewModel.catcherID

        return isPitcherOrCatcher && currentPlayer.speedRating == 2 && previousPlayer.speedRating == 2
    }

    private func warningText(for player: Player) -> String {
        let role: String
        if player.id == viewModel.pitcherID {
            role = "pitcher"
        } else if player.id == viewModel.catcherID {
            role = "catcher"
        } else {
            role = "player"
        }
        return "Warning: No Steal \(role) bats after a No Steal runner"
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

                Form {
                Section {
                    TeamPickerView(viewModel: viewModel)
                }
                Section(header: lineupSectionHeader("Print / Save")) {
                    Button("Share Lineup Grid") {
                        do {
                            lineupPDFURL = try viewModel.createLineupGridPDF()
                            isShowingLineupShareSheet = true
                            lineupExportMessage = "Lineup grid ready."
                        } catch {
                            lineupExportMessage = "Could not create lineup grid: \(error.localizedDescription)"
                        }
                    }

                    Button("Share Book") {
                        do {
                            scorebookPDFURL = try viewModel.createScorebookPDF()
                            lineupPDFURL = scorebookPDFURL
                            isShowingLineupShareSheet = true
                            lineupExportMessage = "Scorebook ready."
                        } catch {
                            lineupExportMessage = "Could not create scorebook: \(error.localizedDescription)"
                        }
                    }

                    if !lineupExportMessage.isEmpty {
                        Text(lineupExportMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section(header: lineupSectionHeader("Batting Order")) {
                    if displayedBatters.isEmpty {
                        Text("Add players first, then they will appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(displayedBatters.enumerated()), id: \.element.id) { index, player in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .fontWeight(.semibold)
                                        .frame(width: 34, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 4) {
                                            Text(lineupDisplayLabel(for: player))
                                            if player.status == .guest {
                                                Text("(Guest)")
                                                    .italic()
                                                    .foregroundStyle(.red)
                                            }
                                        }

                                        if let stats = player.gameChangerStats {
                                            Text(stats.displayText)
                                                .font(.caption2)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }

                                    Spacer()
                                    Text(player.speedRating == 1 ? "Steal" : "No Steal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if hasSlowPitcherCatcherWarning(at: index) {
                                    Text(warningText(for: player))
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .onMove(perform: viewModel.moveBatters)
                    }
                }

                if viewModel.showOnlyNineBattersAndDH {
                    Section(header: lineupSectionHeader("Designated Hitter")) {
                        Picker("DH", selection: Binding(
                            get: { viewModel.designatedHitterID },
                            set: { viewModel.designatedHitterID = $0 }
                        )) {
                            Text("No DH selected").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(lineupDisplayLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        Picker("DH For", selection: Binding(
                            get: { viewModel.designatedHitterForID },
                            set: { viewModel.designatedHitterForID = $0 }
                        )) {
                            Text("Select player").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(lineupDisplayLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        if let dhID = viewModel.designatedHitterID,
                           let dh = viewModel.player(for: dhID) {
                            HStack {
                                Text("DH")
                                    .fontWeight(.semibold)
                                    .frame(width: 34, alignment: .leading)
                                Text(lineupDisplayLabel(for: dh))
                                Spacer()
                            }
                        }

                        if let dhForID = viewModel.designatedHitterForID,
                           let dhFor = viewModel.player(for: dhForID) {
                            HStack {
                                Text("For")
                                    .fontWeight(.semibold)
                                    .frame(width: 34, alignment: .leading)
                                Text(lineupDisplayLabel(for: dhFor))
                                Spacer()
                            }
                        }
                    }
                }

                Section(header: lineupSectionHeader("How this works")) {
                    Text(viewModel.showOnlyNineBattersAndDH ? "Settings are set to show the first 9 batters plus a DH. Use Edit to reorder the batting order." : "All players are shown in the batting order. Use Edit to reorder them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Image(systemName: "list.number")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Lineup")
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
            .onAppear {
                viewModel.syncBattingOrder()
            }
            .sheet(isPresented: $isShowingLineupShareSheet) {
                if let lineupPDFURL {
                    ActivityView(activityItems: [lineupPDFURL])
                } else {
                    Text("No lineup grid available.")
                }
            }
        }
    }

    private func lineupDisplayLabel(for player: Player) -> String {
        let nameParts = player.name.split(separator: " ").map(String.init)

        let baseLabel: String
        if viewModel.showFullNameAndNumber {
            baseLabel = player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            baseLabel = player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }

        return player.status == .guest ? "\(baseLabel) (Guest)" : baseLabel
    }

    private func lineupSectionHeader(_ title: String) -> some View {
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
                Image(systemName: "list.number")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("\(viewModel.selectedSport.rawValue) Lineup Coming Soon")
                    .font(.headline)

                Text("Lineup features for this sport will be available in a future update.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Lineup")
        }
    }
}
