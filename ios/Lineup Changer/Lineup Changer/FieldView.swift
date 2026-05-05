//
//  FieldView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/1/26.
//

import SwiftUI

// MARK: - Baseball Field View

struct AssignmentView: View {
    @ObservedObject var viewModel: LineupViewModel
    @State private var selectedFieldViewPosition: FieldPosition?
    @State private var isShowingFieldPositionPlayerPicker = false

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
                Section(header: fieldSectionHeader("Inning - \(viewModel.selectedInning)")) {
                    Picker("Inning", selection: Binding(
                        get: { viewModel.selectedInning },
                        set: { viewModel.selectInning($0) }
                    )) {
                        ForEach(1...viewModel.numberOfInnings, id: \.self) { inning in
                            Text("\(inning)").tag(inning)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.numberOfInnings) { _, newValue in
                        if viewModel.selectedInning > newValue {
                            viewModel.selectInning(newValue)
                        }
                    }
                }

                if !viewModel.fallBallYouthEnabled {
                    Section(header: fieldSectionHeader("Manual Positions")) {
                        if !viewModel.fallBallEnabled {
                            Picker("Pitcher", selection: Binding(
                                get: { viewModel.pitcherID },
                                set: { newValue in
                                    updatePitcherSelection(newValue)
                                }
                            )) {
                                Text("Choose pitcher").tag(UUID?.none)
                                ForEach(sortedActivePlayers) { player in
                                    Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                                }
                            }
                        }

                        Picker("Catcher", selection: Binding(
                            get: { viewModel.catcherID },
                            set: { newValue in
                                updateCatcherSelection(newValue)
                            }
                        )) {
                            Text("Choose catcher").tag(UUID?.none)
                            ForEach(catcherPickerPlayers) { player in
                                Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                            }
                        }
                    }
                }

                Section(header: fieldSectionHeader("Lineup Actions")) {
                    LineupActionsView(viewModel: viewModel)
                }

                    Section(header: fieldSectionHeader("Field View")) {
                        FieldPreviewView(
                            lineup: viewModel.lineup,
                            showRatings: viewModel.showRatingsOnField,
                            showFullNameAndNumber: viewModel.showFullNameAndNumber,
                            onPositionTap: { position in
                                selectedFieldViewPosition = position
                                isShowingFieldPositionPlayerPicker = true
                            }
                        )
                        .frame(height: UIScreen.main.bounds.width * 0.9)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .confirmationDialog(
                            selectedFieldViewPosition.map { "Choose Player for \(PlayerDisplayHelper.assignedLineupLabel(for: $0))" } ?? "Choose Player",
                            isPresented: $isShowingFieldPositionPlayerPicker,
                            titleVisibility: .visible
                        ) {
                            if let selectedFieldViewPosition {
                                Button("Unassigned") {
                                    updateAssignedLineupPosition(selectedFieldViewPosition, playerID: nil)
                                }

                                ForEach(sortedActivePlayers) { player in
                                    Button(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)) {
                                        updateAssignedLineupPosition(selectedFieldViewPosition, playerID: player.id)
                                    }
                                }
                            }

                            Button("Cancel", role: .cancel) { }
                        }
                    }

                if viewModel.showAssignedLineupTable {
                    Section(header: fieldSectionHeader("Assigned Lineup")) {
                        AssignedLineupView(
                            lineup: viewModel.lineup,
                            sortedPlayers: sortedActivePlayers,
                            onUpdate: { position, playerID in
                                updateAssignedLineupPosition(position, playerID: playerID)
                            },
                            labelProvider: { PlayerDisplayHelper.assignedLineupLabel(for: $0) },
                            displayLabel: { PlayerDisplayHelper.displayLabel(for: $0, showFullNameAndNumber: viewModel.showFullNameAndNumber) },
                            ratingLabel: { PlayerDisplayHelper.ratingLabel(for: $0, at: $1) }
                        )
                    }
                }

                if viewModel.showBenchOnField {
                    Section(header: fieldSectionHeader("Bench")) {
                        let bench = benchPlayers()

                        if bench.isEmpty {
                            Text("No bench players")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(bench) { player in
                                HStack {
                                    PlayerRowView(player: player, viewModel: viewModel)

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

                Section(header: fieldSectionHeader("How assignment works")) {
                    Text(viewModel.fallBallEnabled ? "Fall Ball generates all 9 innings at once and tries to share bench time evenly. Standard Fall Ball automatically uses a different pitcher each inning from players who have Pitcher listed on their profile, keeps catcher manual, then randomly assigns players only to positions listed on their profile. Youth mode randomly assigns all active players across every position, including pitcher and catcher." : "Each inning can have a different field lineup. When you set an inning, the app carries that lineup forward to later empty innings until you manually change or auto-fill those innings. Pitcher and catcher are selected manually. The app fills 1B, 2B, 3B, SS, LF, CF, and RF using the best available rating.")
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
                        Image(systemName: "baseball.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Field")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }
            }
        }
    }

    private func fieldSectionHeader(_ title: String) -> some View {
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

    private var sortedActivePlayers: [Player] {
        viewModel.activePlayers.sorted { lhs, rhs in
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

    private var catcherPickerPlayers: [Player] {
        sortedActivePlayers.filter { player in
            player.id != viewModel.pitcherID
        }
    }

    private func updatePitcherSelection(_ playerID: UUID?) {
        if let playerID {
            clearPlayerFromFieldPositions(playerID)

            if viewModel.catcherID == playerID {
                viewModel.updateCatcher(nil)
            }
        }

        viewModel.updatePitcher(playerID)
    }

    private func updateCatcherSelection(_ playerID: UUID?) {
        if let playerID {
            clearPlayerFromFieldPositions(playerID)

            if viewModel.pitcherID == playerID {
                viewModel.updatePitcher(nil)
            }
        }

        viewModel.updateCatcher(playerID)
    }

    private func updateAssignedLineupPosition(_ position: FieldPosition, playerID: UUID?) {
        if let playerID {
            if viewModel.pitcherID == playerID {
                viewModel.updatePitcher(nil)
            }

            if viewModel.catcherID == playerID {
                viewModel.updateCatcher(nil)
            }

            clearPlayerFromFieldPositions(playerID, except: position)
        }

        viewModel.updateFieldPosition(position, playerID: playerID)
    }

    private func clearPlayerFromFieldPositions(_ playerID: UUID, except keptPosition: FieldPosition? = nil) {
        for position in FieldPosition.allCases {
            guard position != keptPosition else { continue }

            if viewModel.lineup[position]?.id == playerID {
                viewModel.updateFieldPosition(position, playerID: nil)
            }
        }
    }

    private func benchPlayers() -> [Player] {
        let assignedIDs = Set(viewModel.lineup.values.map { $0.id })
        return sortedActivePlayers.filter { !assignedIDs.contains($0.id) }
    }


}

struct LineupActionsView: View {
    @ObservedObject var viewModel: LineupViewModel

    var body: some View {
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
}


struct AssignedLineupView: View {
    let lineup: [FieldPosition: Player]
    let sortedPlayers: [Player]
    let onUpdate: (FieldPosition, UUID?) -> Void
    let labelProvider: (FieldPosition) -> String
    let displayLabel: (Player) -> String
    let ratingLabel: (Player, FieldPosition) -> String

    var body: some View {
        ForEach(FieldPosition.allCases) { position in
            HStack {
                Text(labelProvider(position))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(width: 64, alignment: .leading)

                Picker("", selection: Binding(
                    get: { lineup[position]?.id },
                    set: { newPlayerID in
                        onUpdate(position, newPlayerID)
                    }
                )) {
                    Text("Unassigned").tag(UUID?.none)
                    ForEach(sortedPlayers) { player in
                        Text(displayLabel(player)).tag(Optional(player.id))
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                if let player = lineup[position] {
                    Text(ratingLabel(player, position))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
