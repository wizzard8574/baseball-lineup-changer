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
            Form {
                Section("Team - \(viewModel.selectedTeamName)") {
                    TeamPickerView(viewModel: viewModel)
                }
                Section("Print / Save") {
                    Button("Share Lineup Grid") {
                        do {
                            lineupPDFURL = try viewModel.createLineupGridPDF()
                            isShowingLineupShareSheet = true
                            lineupExportMessage = "Lineup grid ready."
                        } catch {
                            lineupExportMessage = "Could not create lineup grid: \(error.localizedDescription)"
                        }
                    }

                    if !lineupExportMessage.isEmpty {
                        Text(lineupExportMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Batting Order") {
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
                                            Text(viewModel.displayLabel(for: player))
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
                    Section("Designated Hitter") {
                        Picker("DH", selection: Binding(
                            get: { viewModel.designatedHitterID },
                            set: { viewModel.designatedHitterID = $0 }
                        )) {
                            Text("No DH selected").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(viewModel.displayLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        Picker("DH For", selection: Binding(
                            get: { viewModel.designatedHitterForID },
                            set: { viewModel.designatedHitterForID = $0 }
                        )) {
                            Text("Select player").tag(UUID?.none)
                            ForEach(viewModel.activePlayers) { player in
                                Text(viewModel.displayLabel(for: player)).tag(Optional(player.id))
                            }
                        }

                        if let dhID = viewModel.designatedHitterID,
                           let dh = viewModel.player(for: dhID) {
                            HStack {
                                Text("DH")
                                    .fontWeight(.semibold)
                                    .frame(width: 34, alignment: .leading)
                                Text(viewModel.displayLabel(for: dh))
                                Spacer()
                            }
                        }

                        if let dhForID = viewModel.designatedHitterForID,
                           let dhFor = viewModel.player(for: dhForID) {
                            HStack {
                                Text("For")
                                    .fontWeight(.semibold)
                                    .frame(width: 34, alignment: .leading)
                                Text(viewModel.displayLabel(for: dhFor))
                                Spacer()
                            }
                        }
                    }
                }

                Section("How this works") {
                    Text(viewModel.showOnlyNineBattersAndDH ? "Settings are set to show the first 9 batters plus a DH. Use Edit to reorder the batting order." : "All players are shown in the batting order. Use Edit to reorder them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Lineup")
            .toolbar {
                EditButton()
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
            .navigationTitle("Lineup")
        }
    }
}

struct BaseballFieldLineupView: View {
    let lineup: [FieldPosition: Player]
    let showRatings: Bool
    let showFullNameAndNumber: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.green.opacity(0.22))

                outfieldShape(width: width, height: height)
                    .fill(Color.green.opacity(0.35))

                infieldShape(width: width, height: height)
                    .fill(Color.brown.opacity(0.45))


                baseDiamond(width: width, height: height)
                    .stroke(Color.white.opacity(0.95), lineWidth: 2)

                baseMarker(at: CGPoint(x: width * 0.50, y: height * 0.82), size: 18)
                baseMarker(at: CGPoint(x: width * 0.75, y: height * 0.60), size: 13)
                baseMarker(at: CGPoint(x: width * 0.50, y: height * 0.39), size: 13)
                baseMarker(at: CGPoint(x: width * 0.25, y: height * 0.60), size: 13)

                Circle()
                    .fill(Color.brown.opacity(0.45))
                    .frame(width: 64, height: 64)
                    .position(x: width * 0.50, y: height * 0.61)

                positionMarker(.centerField, at: CGPoint(x: width * 0.50, y: height * 0.14))
                positionMarker(.leftField, at: CGPoint(x: width * 0.20, y: height * 0.28))
                positionMarker(.rightField, at: CGPoint(x: width * 0.80, y: height * 0.28))
                positionMarker(.shortstop, at: CGPoint(x: width * 0.36, y: height * 0.45))
                positionMarker(.secondBase, at: CGPoint(x: width * 0.64, y: height * 0.45))
                positionMarker(.thirdBase, at: CGPoint(x: width * 0.25, y: height * 0.62))
                positionMarker(.firstBase, at: CGPoint(x: width * 0.75, y: height * 0.62))
                positionMarker(.pitcher, at: CGPoint(x: width * 0.50, y: height * 0.62))
                positionMarker(.catcher, at: CGPoint(x: width * 0.50, y: height * 0.90))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private func outfieldShape(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: width * 0.05, y: height * 0.56))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.95, y: height * 0.56),
                control: CGPoint(x: width * 0.50, y: height * -0.04)
            )
            path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.92))
            path.closeSubpath()
        }
    }

    private func infieldShape(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: width * 0.50, y: height * 0.82))
            path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.60))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.50, y: height * 0.39),
                control: CGPoint(x: width * 0.66, y: height * 0.43)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.25, y: height * 0.60),
                control: CGPoint(x: width * 0.34, y: height * 0.43)
            )
            path.closeSubpath()
        }
    }


    private func baseDiamond(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: width * 0.50, y: height * 0.82))
            path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.60))
            path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.39))
            path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.60))
            path.closeSubpath()
        }
    }

    private func baseMarker(at point: CGPoint, size: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .position(point)
    }

    private func positionMarker(_ position: FieldPosition, at point: CGPoint) -> some View {
        let player = lineup[position]
        let rating = player?.positionRatings[position]
        let positionText = label(for: position)

        return VStack(spacing: 3) {
            Text(positionText)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.9))
                .clipShape(Capsule())

            Text(playerLabel(player))
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .foregroundStyle(Color(uiColor: .label))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .frame(width: 96)
                .background(Color(uiColor: .systemBackground).opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            if showRatings, let rating {
                Text("Rating \(rating)")
                    .font(.caption2)
                    .foregroundStyle(Color(uiColor: .label))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(uiColor: .systemBackground).opacity(0.80))
                    .clipShape(Capsule())
            }
        }
        .position(point)
    }

    private func playerLabel(_ player: Player?) -> String {
        guard let player else { return "—" }

        let nameParts = player.name.split(separator: " ").map(String.init)
        let lastName = nameParts.last ?? player.name
        let firstInitial = nameParts.first?.first.map { "\($0)." } ?? ""
        let initialLastName = firstInitial.isEmpty ? lastName : "\(firstInitial) \(lastName)"

        let baseLabel: String
        if showFullNameAndNumber {
            baseLabel = player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            baseLabel = player.number.isEmpty ? initialLastName : "#\(player.number) \(initialLastName)"
        }

        return player.status == .guest ? "\(baseLabel) (Guest)" : baseLabel
    }

    private func label(for position: FieldPosition) -> String {
        position.rawValue
    }
}
