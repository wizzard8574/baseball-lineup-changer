// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballLineupView+BattingOrder.swift
//
//
//
import SwiftUI

// MARK: - Baseball Lineup Batting Order
extension BaseballLineupView {
    var battingOrderSection: some View {
        lineupGroupedSection("Batting Order") {
            if hasImportedGameChangerStats {
                gameChangerSortMenu
            }

            if !displayedBatters.isEmpty || !benchBatters.isEmpty {
                lineupRowDivider
            }

            if displayedBatters.isEmpty && benchBatters.isEmpty {
                Text("Add players first, then they will appear here.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(displayedBatters.enumerated()), id: \.element.id) { index, player in
                    if index > 0 {
                        lineupRowDivider
                    }

                    battingOrderRow(index: index, player: player)
                }

                if viewModel.baseballUsesNineBatterAndDH {
                    if !displayedBatters.isEmpty {
                        lineupRowDivider
                    }

                    lineupDropRow
                }
            }
        }
    }

    private var gameChangerSortMenu: some View {
        Menu {
            Button("AVG") {
                viewModel.sortBattingOrderByGameChangerStat(.avg)
            }

            Button("OBP") {
                viewModel.sortBattingOrderByGameChangerStat(.obp)
            }

            Button("OPS") {
                viewModel.sortBattingOrderByGameChangerStat(.ops)
            }

            Button("SLG") {
                viewModel.sortBattingOrderByGameChangerStat(.slg)
            }

            Button("Hits") {
                viewModel.sortBattingOrderByGameChangerStat(.hits)
            }

            Button("RBI") {
                viewModel.sortBattingOrderByGameChangerStat(.rbi)
            }

            Button("Runs") {
                viewModel.sortBattingOrderByGameChangerStat(.runs)
            }

            Button("Walks") {
                viewModel.sortBattingOrderByGameChangerStat(.walks)
            }

            Button("Strikeouts") {
                viewModel.sortBattingOrderByGameChangerStat(.strikeouts, descending: false)
            }
        } label: {
            Label("Sort by GameChanger Stats", systemImage: "arrow.up.arrow.down.circle")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        }
    }

    var benchSection: some View {
        lineupGroupedSection("Bench") {
            if shouldShowLineupCountWarning {
                Text(lineupCountWarningText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.vertical, 10)

                lineupRowDivider
            }

            benchDropRow

            if benchBatters.isEmpty {
                lineupRowDivider

                Text("No bench players.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(benchBatters) { player in
                    lineupRowDivider
                    benchPlayerRow(player)
                }
            }
        }
    }

    private var lineupDropRow: some View {
        Label("Drop here to add a batter to the lineup", systemImage: "arrow.up.to.line.compact")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                guard let rawID = items.first,
                      let playerID = UUID(uuidString: rawID) else { return false }

                return handleBaseballLineupDrop(playerID, toBattingOrderIndex: battingOrderBatters.count)
            }
            .onDrop(of: baseballDropTypes, isTargeted: nil) { providers in
                handleBaseballLineupDrop(providers, toBattingOrderIndex: battingOrderBatters.count)
            }
    }

    private var benchDropRow: some View {
        Label(viewModel.baseballUsesNineBatterAndDH ? "Drop a batter on a bench player to replace them" : "Drop here to move a player to the bench", systemImage: "arrow.left.arrow.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                guard let rawID = items.first,
                      let playerID = UUID(uuidString: rawID) else { return false }

                return handleBaseballBenchDrop(playerID)
            }
            .onDrop(of: baseballDropTypes, isTargeted: nil) { providers in
                handleBaseballBenchDrop(providers)
            }
    }

    private func benchPlayerRow(_ player: Player) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(lineupDisplayLabel(for: player))
                        .font(.headline)

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

            Button {
                viewModel.moveBatter(playerID: player.id, toBattingOrderIndex: battingOrderBatters.count)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add \(lineupDisplayLabel(for: player)) to lineup")

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .baseballLineupDragSource(player: player)
        .dropDestination(for: String.self) { items, _ in
            guard let rawID = items.first,
                  let playerID = UUID(uuidString: rawID) else { return false }

            return handleBaseballBenchDrop(playerID, on: player)
        }
        .onDrop(of: baseballDropTypes, isTargeted: nil) { providers in
            handleBaseballBenchDrop(providers, before: player)
        }
    }

    private func battingOrderRow(index: Int, player: Player) -> some View {
        let orderPlayer = battingOrderBatters.indices.contains(index) ? battingOrderBatters[index] : player

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 12) {
                Text(battingOrderBadgeText(index: index, player: orderPlayer))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .frame(width: 48, height: 34)
                    .background(.blue, in: Capsule())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(lineupDisplayLabel(for: player))
                            .font(.headline)

                        if isDesignatedHitterRow(index: index, player: player) {
                            Text("DH")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue, in: Capsule())
                        }

                        if player.status == .guest {
                            Text("(Guest)")
                                .italic()
                                .foregroundStyle(.red)
                        }
                    }

                    if let dhForText = designatedHitterForText(at: index) {
                        Text(dhForText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

                if viewModel.baseballUsesNineBatterAndDH {
                    Button(role: .destructive) {
                        viewModel.moveBatterToBench(playerID: orderPlayer.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Move \(lineupDisplayLabel(for: orderPlayer)) to bench")
                }

                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
            }

            if hasSlowPitcherCatcherWarning(at: index) {
                Text(warningText(for: player))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .baseballLineupDragSource(player: orderPlayer)
        .dropDestination(for: String.self) { items, _ in
            guard let rawID = items.first,
                  let playerID = UUID(uuidString: rawID) else { return false }

            return handleBaseballLineupDrop(playerID, toBattingOrderIndex: index)
        }
        .onDrop(of: baseballDropTypes, isTargeted: nil) { providers in
            handleBaseballLineupDrop(providers, toBattingOrderIndex: index)
        }
    }
}
