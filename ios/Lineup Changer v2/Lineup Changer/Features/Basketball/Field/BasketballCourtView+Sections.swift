// Created by Rich Morris on 5/15/26.
// Lineup Changer
// BasketballCourtView+Sections.swift
//
//
//
import SwiftUI

// MARK: - Basketball Court Sections
extension BasketballCourtView {
    @ViewBuilder
    var basketballCourtSections: some View {
        teamPickerSection
        periodPickerSection
        lineupActionsSection
        courtPreviewSection

        if viewModel.showAssignedBasketballLineup {
            assignedLineupSection
        }

        if viewModel.showBasketballBenchOnCourt {
            benchSection
        }

        infoSection
    }

    private var teamPickerSection: some View {
        basketballCourtGroupedSection {
            TeamPickerView(viewModel: viewModel)
        }
    }

    private var periodPickerSection: some View {
        basketballCourtGroupedSection("\(viewModel.basketballPeriodFormat.courtPeriodTitle) - \(selectedBasketballPeriod)") {
            Picker(viewModel.basketballPeriodFormat.courtPeriodTitle, selection: $selectedBasketballPeriod) {
                ForEach(1...viewModel.basketballPeriodFormat.periodCount, id: \.self) { period in
                    Text("\(period)").tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var lineupActionsSection: some View {
        basketballCourtGroupedSection("Lineup Actions") {
            Button {
                basketballCourtBenchPlacementWarningText = nil
                viewModel.autoFillBasketballCourtPositions(for: selectedBasketballPeriod)
            } label: {
                Label("Auto Fill Positions", systemImage: "wand.and.stars")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            Divider()

            Button {
                viewModel.useBasketballCourtLineupForAllPeriods(from: selectedBasketballPeriod)
            } label: {
                Label("Use this Lineup for All \(viewModel.basketballPeriodFormat.courtPeriodPluralTitle)", systemImage: "square.on.square")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            Divider()

            Button(role: .destructive) {
                viewModel.clearBasketballCourtLineup(for: selectedBasketballPeriod)
            } label: {
                Label("Clear \(viewModel.basketballPeriodFormat.courtPeriodTitle)", systemImage: "eraser")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)

            Divider()

            Button(role: .destructive) {
                viewModel.clearAllBasketballCourtLineups()
            } label: {
                Label("Clear All", systemImage: "trash")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        }
    }

    private var courtPreviewSection: some View {
        basketballCourtGroupedSection("Court View") {
            BasketballCourtPreviewView(
                lineup: basketballCourtLineup,
                showRatings: viewModel.showRatingsOnCourt,
                showFullNameAndNumber: viewModel.showFullNameAndNumberInBasketball,
                onPositionTap: { position in
                    selectedCourtPosition = position
                    isShowingCourtPositionPlayerPicker = true
                }
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var assignedLineupSection: some View {
        basketballCourtGroupedSection("Assigned Lineup") {
            ForEach(BasketballPosition.allCases) { position in
                HStack {
                    Text(position.lineupBubbleLabel)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(width: 64, alignment: .leading)

                    Picker("", selection: Binding(
                        get: { viewModel.basketballCourtPlayer(for: position, period: selectedBasketballPeriod)?.id },
                        set: { playerID in
                            updateBasketballCourtPosition(position, playerID: playerID)
                        }
                    )) {
                        Text("Unassigned").tag(UUID?.none)

                        ForEach(basketballCourtPickerPlayers(for: position)) { player in
                            Text(basketballCourtDisplayLabel(for: player)).tag(Optional(player.id))
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    if viewModel.showRatingsOnCourt,
                       let player = viewModel.basketballCourtPlayer(for: position, period: selectedBasketballPeriod) {
                        Text(basketballCourtRatingLabel(for: player, at: position))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var benchSection: some View {
        basketballCourtGroupedSection("Bench") {
            let benchPlayers = viewModel.basketballCourtBenchPlayers(for: selectedBasketballPeriod)

            if let basketballCourtBenchPlacementWarningText {
                Text(basketballCourtBenchPlacementWarningText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.bottom, 6)
            }

            if benchPlayers.isEmpty {
                Text("No bench players")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(benchPlayers) { player in
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(basketballCourtDisplayLabel(for: player))
                                .font(.headline)

                            if viewModel.showRatingsOnCourt {
                                Text(PlayerDisplayHelper.basketballPositionSummary(for: player))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button("Put on Court") {
                            putBasketballBenchPlayerOnCourt(player)
                        }
                        .buttonStyle(.borderedProminent)

                        Menu("Position") {
                            ForEach(BasketballPosition.allCases) { position in
                                Button("Move to \(position.lineupBubbleLabel)") {
                                    basketballCourtBenchPlacementWarningText = nil
                                    updateBasketballCourtPosition(position, playerID: player.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var infoSection: some View {
        basketballCourtGroupedSection("How assignment works") {
            Text("Each quarter or half can have its own court assignment. Auto Fill Positions picks the best rated available player for each spot and does not use the same player twice. Put on Court uses a bench player's highest rated position. The Position menu and Assigned Lineup pickers let you manually place players anywhere.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
