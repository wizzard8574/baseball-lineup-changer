// Created by Rich Morris on 5/13/26.
// Lineup Changer
// BasketballLineupView+Sections.swift
//
//
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Basketball Lineup Sections
extension BasketballLineupView {
    @ViewBuilder
    var basketballLineupSections: some View {
        teamPickerSection
        shareSection
        lineupActionsSection
        startingLineupSection
        benchSection
        infoSection
    }

    private var teamPickerSection: some View {
        basketballLineupGroupedSection {
            TeamPickerView(viewModel: viewModel)
        }
    }

    private var actionsSection: some View {
        basketballLineupGroupedSection {
            Button {
                viewModel.assignBestBasketballLineup()
            } label: {
                Label("Auto Assign Starting Lineup", systemImage: "wand.and.stars")
            }
        }
    }

    private var lineupActionsSection: some View {
        basketballLineupGroupedSection {
            Button(role: .destructive) {
                viewModel.clearBasketballLineupToBench()
            } label: {
                Label("Clear Lineup", systemImage: "arrow.down.to.line.compact")
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        }
    }

    private var shareSection: some View {
        basketballLineupGroupedSection("Print / Save") {
            Button {
                prepareBasketballLineupShare()
            } label: {
                Label("Share Starting Lineup", systemImage: "square.and.arrow.up")
            }

            if !basketballLineupExportMessage.isEmpty {
                Text(basketballLineupExportMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var startingLineupSection: some View {
        basketballLineupGroupedSection("Starting Lineup") {
            autoAssignStartingLineupButton

            if viewModel.basketballLineupPlayers.isEmpty {
                basketballLineupRowDivider

                Text("Add players first, then they will appear here.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(BasketballPosition.allCases.enumerated()), id: \.element.id) { index, position in
                    basketballLineupRowDivider
                    startingLineupRow(position: position, index: index)
                }

                if !basketballLineupStatusMessage.isEmpty {
                    Text(basketballLineupStatusMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.top, 10)
                }
            }
        }
    }

    private var autoAssignStartingLineupButton: some View {
        Button {
            viewModel.assignBestBasketballLineup()
        } label: {
            Label("Auto Assign Starting Lineup", systemImage: "wand.and.stars")
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }

    private func startingLineupRow(position: BasketballPosition, index: Int) -> some View {
        let player = viewModel.basketballStartingPlayer(for: position)

        return HStack(alignment: .center, spacing: 12) {
            Text(position.lineupBubbleLabel)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 34)
                .background(.blue, in: Capsule())

            if let player {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(basketballLineupDisplayLabel(for: player))
                            .font(.headline)

                        if player.status == .guest {
                            Text("(Guest)")
                                .italic()
                                .foregroundStyle(.red)
                        }
                    }

                    Text(ratingText(for: player, position: position))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }
            } else {
                Text("Empty spot")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let player {
                Button(role: .destructive) {
                    removeBasketballStarter(player, from: position)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Move \(basketballLineupDisplayLabel(for: player)) to bench")
            }

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .basketballLineupDragSource(player: player)
        .dropDestination(for: String.self) { items, _ in
            guard let rawID = items.first,
                  let playerID = UUID(uuidString: rawID) else { return false }

            return handleBasketballLineupDrop(playerID, toStartingIndex: index)
        }
        .onDrop(of: basketballDropTypes, isTargeted: nil) { providers in
            handleBasketballLineupDrop(providers, toStartingIndex: index)
        }
    }

    private var benchSection: some View {
        basketballLineupGroupedSection("Bench") {
            benchDropRow

            if viewModel.basketballBenchPlayers.isEmpty {
                basketballLineupRowDivider

                Text("No bench players.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(viewModel.basketballBenchPlayers.enumerated()), id: \.element.id) { index, player in
                    basketballLineupRowDivider
                    benchPlayerRow(player)
                }
            }
        }
    }

    private var benchDropRow: some View {
        Label("Drop a starter on a bench player to replace them", systemImage: "arrow.left.arrow.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }

    private func benchPlayerRow(_ player: Player) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(basketballLineupDisplayLabel(for: player))
                        .font(.headline)

                    if player.status == .guest {
                        Text("(Guest)")
                            .italic()
                            .foregroundStyle(.red)
                    }
                }

                Text(PlayerDisplayHelper.basketballPositionSummary(for: player))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Spacer()

            Button {
                addBasketballBenchPlayer(player)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add \(basketballLineupDisplayLabel(for: player)) to starting lineup")

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .basketballLineupDragSource(player: player)
        .dropDestination(for: String.self) { items, _ in
            guard let rawID = items.first,
                  let playerID = UUID(uuidString: rawID) else { return false }

            return handleBasketballBenchDrop(playerID, on: player)
        }
        .onDrop(of: basketballDropTypes, isTargeted: nil) { providers in
            handleBasketballBenchDrop(providers, on: player)
        }
    }

    private var infoSection: some View {
        basketballLineupGroupedSection("How this works") {
            Text("Auto assign picks the best available rated player for positions 1 through 5. Drag players between Starting Lineup and Bench to make manual changes.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

}
