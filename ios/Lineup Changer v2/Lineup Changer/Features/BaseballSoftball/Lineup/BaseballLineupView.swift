// Created by Rich Morris on 5/5/26.
// Lineup Changer
// LineupView.swift
//
//
//
// LineupView.swift contains the batting order tab for baseball/softball.
// It lets coaches review and reorder the batting lineup, export lineup PDFs,
// configure designated hitter display, and view batting warnings.
import SwiftUI

// MARK: - Lineup Order View

// Main lineup screen shown in the Lineup tab.
// This view switches between the baseball/softball lineup editor and placeholder
// content for sports that are not implemented yet.
struct LineupOrderView: View {
    // Shared app state and lineup management logic.
    @ObservedObject var viewModel: LineupViewModel

    // Controls presentation of the iOS share sheet for generated PDF files.
    @State private var isShowingLineupShareSheet = false

    // URL for the most recently generated lineup PDF.
    @State private var lineupPDFURL: URL?

    // URL for the most recently generated scorebook PDF.
    @State private var scorebookPDFURL: URL?

    // Status text shown after attempting to generate a shareable PDF.
    @State private var lineupExportMessage = ""

    // MARK: - Computed Player Lists
    // Batting order resolved from stored player IDs, excluding inactive players.
    private var orderedPlayers: [Player] {
        viewModel.battingOrderIDs
            .compactMap { viewModel.player(for: $0) }
            .filter { $0.status == .active }
    }

    // Applies the setting that limits the visible batting order to the first nine hitters.
    private var displayedBatters: [Player] {
        if viewModel.showOnlyNineBattersAndDH {
            return Array(orderedPlayers.prefix(9))
        }

        return orderedPlayers
    }

    // MARK: - Warning Helpers
    // Detects when a No Steal pitcher/catcher follows another No Steal runner.
    private func hasSlowPitcherCatcherWarning(at index: Int) -> Bool {
        // Only evaluate warnings when enabled and when the current/previous rows exist.
        guard viewModel.showSlowSpeedBattingWarnings,
              index > 0,
              displayedBatters.indices.contains(index),
              displayedBatters.indices.contains(index - 1) else { return false }

        // Compare the current batter against the previous batter in the displayed order.
        let currentPlayer = displayedBatters[index]
        let previousPlayer = displayedBatters[index - 1]
        let isPitcherOrCatcher = currentPlayer.id == viewModel.pitcherID || currentPlayer.id == viewModel.catcherID

        return isPitcherOrCatcher && currentPlayer.speedRating == 2 && previousPlayer.speedRating == 2
    }

    // Builds the warning message using the player's defensive role when available.
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

    // MARK: - Body
    // Shows the baseball lineup editor for baseball/softball and a placeholder otherwise.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            baseballView
        default:
            comingSoonView
        }
    }

    // MARK: - Baseball / Softball Layout
    // Full baseball/softball lineup interface.
    private var baseballView: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed background used across the app.
                AppSportsBackground()

                Form {
                // Team picker keeps the lineup tied to the selected team snapshot.
                Section {
                    TeamPickerView(viewModel: viewModel)
                }
                // PDF generation and sharing controls.
                Section(header: lineupSectionHeader("Print / Save")) {
                    // Generate and share the lineup grid PDF.
                    Button("Share Lineup Grid") {
                        do {
                            // Store the generated file URL so ActivityView can share it.
                            lineupPDFURL = try viewModel.createLineupGridPDF()
                            isShowingLineupShareSheet = true
                            lineupExportMessage = "Lineup grid ready."
                        } catch {
                            lineupExportMessage = "Could not create lineup grid: \(error.localizedDescription)"
                        }
                    }

                    // Generate and share the full scorebook PDF.
                    Button("Share Book") {
                        do {
                            // Reuse the lineupPDFURL share path for the generated scorebook file.
                            scorebookPDFURL = try viewModel.createScorebookPDF()
                            lineupPDFURL = scorebookPDFURL
                            isShowingLineupShareSheet = true
                            lineupExportMessage = "Scorebook ready."
                        } catch {
                            lineupExportMessage = "Could not create scorebook: \(error.localizedDescription)"
                        }
                    }

                    // Show success or failure feedback after PDF generation.
                    if !lineupExportMessage.isEmpty {
                        Text(lineupExportMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                // Editable batting order list.
                Section(header: lineupSectionHeader("Batting Order")) {
                    // Empty-state message shown before players are added.
                    if displayedBatters.isEmpty {
                        Text("Add players first, then they will appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(displayedBatters.enumerated()), id: \.element.id) { index, player in
                            // Each row shows batting position, player label, stats, speed, and warnings.
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    // One-based batting order position.
                                    Text("\(index + 1).")
                                        .fontWeight(.semibold)
                                        .frame(width: 34, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 3) {
                                        // Player name/number label, with guest status emphasized when needed.
                                        HStack(spacing: 4) {
                                            Text(lineupDisplayLabel(for: player))
                                            if player.status == .guest {
                                                Text("(Guest)")
                                                    .italic()
                                                    .foregroundStyle(.red)
                                            }
                                        }

                                        // Optional imported GameChanger batting stat summary.
                                        if let stats = player.gameChangerStats {
                                            Text(stats.displayText)
                                                .font(.caption2)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }

                                    Spacer()
                                    // Speed rating displayed as a simple steal/no-steal label.
                                    Text(player.speedRating == 1 ? "Steal" : "No Steal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                // Inline warning for slow pitcher/catcher batting behind another slow runner.
                                if hasSlowPitcherCatcherWarning(at: index) {
                                    Text(warningText(for: player))
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        // Enables Edit mode drag-and-drop reordering.
                        .onMove(perform: viewModel.moveBatters)
                    }
                }

                // Optional designated hitter controls when the lineup is limited to nine batters.
                if viewModel.showOnlyNineBattersAndDH {
                    Section(header: lineupSectionHeader("Designated Hitter")) {
                        // Selects the player who will bat as designated hitter.
                        Picker("DH", selection: Binding(
                            get: { viewModel.designatedHitterID },
                            set: { viewModel.designatedHitterID = $0 }
                        )) {
                            Text("No DH selected").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(lineupDisplayLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        // Selects the player the DH is batting for.
                        Picker("DH For", selection: Binding(
                            get: { viewModel.designatedHitterForID },
                            set: { viewModel.designatedHitterForID = $0 }
                        )) {
                            Text("Select player").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(lineupDisplayLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        // Summary row for the selected DH.
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

                        // Summary row for the player covered by the DH.
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

                // Help text explaining the current batting order mode.
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
                        // Decorative lineup icon used in the custom navigation title.
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

                // Edit button enables manual batting-order reordering.
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            // Keep batting order synchronized when the lineup screen opens.
            .onAppear {
                viewModel.syncBattingOrder()
            }
            // Presents the system share sheet for the generated PDF file.
            .sheet(isPresented: $isShowingLineupShareSheet) {
                if let lineupPDFURL {
                    ActivityView(activityItems: [lineupPDFURL])
                } else {
                    Text("No lineup grid available.")
                }
            }
        }
    }
}
