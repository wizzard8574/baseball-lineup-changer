// Created by Rich Morris on 5/5/26.
// Lineup Changer
// BaseballSoftballFieldView.swift
//
//
//
// BaseballSoftballFieldView.swift contains the baseball/softball field assignment
// workflow for the Field tab.
import SwiftUI

// MARK: - Baseball / Softball Field View
// Coordinates inning-based lineups, manual position selection, auto-fill tools,
// bench management, and the interactive baseball/softball field preview.
struct BaseballSoftballFieldView: View {
    // Shared application state and lineup management logic.
    @ObservedObject var viewModel: LineupViewModel
    // Tracks which field position marker was tapped in the field preview.
    @State private var selectedFieldViewPosition: FieldPosition?
    // Controls presentation of the field position assignment dialog.
    @State private var isShowingFieldPositionPlayerPicker = false

    // Detects wider iPad-style layouts so the field and lineup table can sit side by side.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Only iPad should use the two-column field/lineup presentation.
    // iPhone landscape can also report a regular horizontal size class, so device idiom is checked too.
    private var usesSideBySideFieldLayout: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed app background.
                AppSportsBackground()

                Form {
                    // Team selection controls.
                    Section {
                        TeamPickerView(viewModel: viewModel)
                    }

                    // Inning picker controls which inning lineup is currently being edited.
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

                    // Standard mode keeps pitcher/catcher manually controlled.
                    if !viewModel.fallBallYouthEnabled {
                        Section(header: fieldSectionHeader("Manual Positions")) {
                            if !viewModel.fallBallEnabled {
                                Picker("Pitcher", selection: Binding(
                                    get: { viewModel.pitcherID },
                                    set: { updatePitcherSelection($0) }
                                )) {
                                    Text("Choose pitcher").tag(UUID?.none)
                                    ForEach(sortedActivePlayers) { player in
                                        Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                                    }
                                }
                            }

                            Picker("Catcher", selection: Binding(
                                get: { viewModel.catcherID },
                                set: { updateCatcherSelection($0) }
                            )) {
                                Text("Choose catcher").tag(UUID?.none)
                                ForEach(catcherPickerPlayers) { player in
                                    Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                                }
                            }
                        }
                    }

                    // Buttons for auto-fill, copying, and clearing inning lineups.
                    Section(header: fieldSectionHeader("Lineup Actions")) {
                        LineupActionsView(viewModel: viewModel)
                    }

                    if usesSideBySideFieldLayout {
                        // iPad layout places the field preview and assignment table next to each other.
                        Section {
                            HStack(alignment: .top, spacing: 18) {
                                VStack(alignment: .leading, spacing: 10) {
                                    fieldSectionHeader("Field View")
                                    fieldPreviewContent
                                        .frame(minHeight: 440)
                                }
                                .frame(maxWidth: .infinity, alignment: .top)

                                if viewModel.showAssignedLineupTable {
                                    VStack(alignment: .leading, spacing: 10) {
                                        fieldSectionHeader("Assigned Lineup")
                                        assignedLineupContent
                                            .padding(.top, 40)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .top)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        // Compact layout keeps the field preview and assigned lineup stacked.
                        Section(header: fieldSectionHeader("Field View")) {
                            fieldPreviewContent
                                .frame(height: UIScreen.main.bounds.width * 0.9)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }

                        if viewModel.showAssignedLineupTable {
                            Section(header: fieldSectionHeader("Assigned Lineup")) {
                                assignedLineupContent
                            }
                        }
                    }

                    // Bench management section for active players not currently in the field.
                    if viewModel.showBenchOnField {
                        Section(header: fieldSectionHeader("Bench")) {
                            let bench = benchPlayers()

                            if bench.isEmpty {
                                Text("No bench players")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(bench) { player in
                                    HStack {
                                        BaseballPlayerRowView(player: player, viewModel: viewModel)

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

                    // Explains the lineup generation logic for standard and Fall Ball modes.
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

    // MARK: - Section Header Styling
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

    // MARK: - Player Lists
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

    // Prevents the same player from being both pitcher and catcher simultaneously.
    private var catcherPickerPlayers: [Player] {
        sortedActivePlayers.filter { player in
            player.id != viewModel.pitcherID
        }
    }

    // MARK: - Assignment Updates
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

            if viewModel.lineup[position] == playerID {
                viewModel.updateFieldPosition(position, playerID: nil)
            }
        }
    }

    private func benchPlayers() -> [Player] {
        let assignedIDs = Set(viewModel.lineup.values)
        return sortedActivePlayers.filter { !assignedIDs.contains($0.id) }
    }

    // MARK: - Field / Lineup Sections
    private var fieldPreviewContent: some View {
        FieldPreviewView(
            lineup: viewModel.resolvedLineup,
            showRatings: viewModel.showRatingsOnField,
            showFullNameAndNumber: viewModel.showFullNameAndNumber,
            onPositionTap: { position in
                selectedFieldViewPosition = position
                isShowingFieldPositionPlayerPicker = true
            }
        )
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

    private var assignedLineupContent: some View {
        AssignedLineupView(
            lineup: viewModel.resolvedLineup,
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
