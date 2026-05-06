// Created by Rich Morris on 5/5/26.
// Lineup Changer
// FieldView.swift
//
//
//
// FieldView.swift contains the primary baseball/softball field assignment screen.
// It manages inning selection, lineup assignment actions, field visualization,
// bench management, and manual defensive position controls.
import SwiftUI

// MARK: - Assignment View
// Main field assignment screen.
// This view coordinates inning-based lineups, manual position selection,
// auto-fill tools, and the interactive field preview.
struct AssignmentView: View {
    // Shared application state and lineup management logic.
    @ObservedObject var viewModel: LineupViewModel
    // Tracks which field position marker was tapped in the field preview.
    @State private var selectedFieldViewPosition: FieldPosition?
    // Controls presentation of the field position assignment dialog.
    @State private var isShowingFieldPositionPlayerPicker = false

    // Detects wider iPad-style layouts so the field and lineup table can sit side by side.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Layout Mode Helpers
    // Only iPad should use the two-column field/lineup presentation.
    // iPhone landscape can also report a regular horizontal size class, so device idiom is checked too.
    private var usesSideBySideFieldLayout: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    // Switches between the active sport implementation and placeholder screens.
    var body: some View {
        switch viewModel.selectedSport {
        case .baseballSoftball:
            baseballView
        default:
            comingSoonView
        }
    }

    // MARK: - Baseball / Softball Layout
    // Full baseball/softball field assignment workflow.
    private var baseballView: some View {
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
                        // Changing innings loads and edits a different stored lineup.
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
                            // Keep the selected inning inside the valid inning range.
                            if viewModel.selectedInning > newValue {
                                viewModel.selectInning(newValue)
                            }
                        }
                    }

                    // Standard mode keeps pitcher/catcher manually controlled.
                    if !viewModel.fallBallYouthEnabled {
                        Section(header: fieldSectionHeader("Manual Positions")) {
                            // Standard mode allows manual pitcher assignment.
                            if !viewModel.fallBallEnabled {
                                Picker("Pitcher", selection: Binding(
                                    get: { viewModel.pitcherID },
                                    set: { newValue in
                                        // Prevent duplicate field assignments while updating pitcher.
                                        updatePitcherSelection(newValue)
                                    }
                                )) {
                                    Text("Choose pitcher").tag(UUID?.none)
                                    // Only active players are eligible for field positions.
                                    ForEach(sortedActivePlayers) { player in
                                        Text(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)).tag(Optional(player.id))
                                    }
                                }
                            }

                            Picker("Catcher", selection: Binding(
                                get: { viewModel.catcherID },
                                set: { newValue in
                                    // Prevent duplicate field assignments while updating catcher.
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

                                        // Lower the assignment table so its rows line up closer to the field image.
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

                        // Optional table view showing all field assignments at once.
                        if viewModel.showAssignedLineupTable {
                            Section(header: fieldSectionHeader("Assigned Lineup")) {
                                assignedLineupContent
                            }
                        }
                    }

                    // Bench management section for active players not currently in the field.
                    if viewModel.showBenchOnField {
                        Section(header: fieldSectionHeader("Bench")) {
                            // Bench players are active players without a current field assignment.
                            let bench = benchPlayers()

                            if bench.isEmpty {
                                Text("No bench players")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(bench) { player in
                                    HStack {
                                        PlayerRowView(player: player, viewModel: viewModel)

                                        Spacer()

                                        // Automatically place the player into the next open field position.
                                        Button("Put In Field") {
                                            viewModel.placeBenchPlayerInField(playerID: player.id)
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Menu("Position") {
                                            // Manual override to place a bench player into a specific position.
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
                        // Decorative baseball icon used in the navigation title.
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
    // Shared styling helper for section headers used throughout the field screen.
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

    // MARK: - Coming Soon Placeholder
    // Placeholder screen shown for sports that do not yet support field assignments.
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

    // MARK: - Player Lists
    // Active players sorted by jersey number first, then alphabetically by name.
    private var sortedActivePlayers: [Player] {
        viewModel.activePlayers.sorted { lhs, rhs in
            let lhsNumber = Int(lhs.number)
            let rhsNumber = Int(rhs.number)
            // Numeric jersey numbers sort ahead of players without valid numbers.
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
    // Updates pitcher assignment while removing duplicate assignments elsewhere on the field.
    private func updatePitcherSelection(_ playerID: UUID?) {
        if let playerID {
            // Remove the player from any currently assigned defensive position first.
            clearPlayerFromFieldPositions(playerID)

            // Pitcher and catcher cannot be the same player.
            if viewModel.catcherID == playerID {
                viewModel.updateCatcher(nil)
            }
        }

        viewModel.updatePitcher(playerID)
    }

    // Updates catcher assignment while removing duplicate assignments elsewhere on the field.
    private func updateCatcherSelection(_ playerID: UUID?) {
        if let playerID {
            clearPlayerFromFieldPositions(playerID)

            if viewModel.pitcherID == playerID {
                viewModel.updatePitcher(nil)
            }
        }

        viewModel.updateCatcher(playerID)
    }

    // Updates a defensive position assignment while keeping every player assigned only once.
    private func updateAssignedLineupPosition(_ position: FieldPosition, playerID: UUID?) {
        if let playerID {
            // Remove the player from pitcher/catcher if they are moving into a field position.
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

    // Clears a player from all field positions except an optional retained position.
    // This guarantees each player only occupies one field slot at a time.
    private func clearPlayerFromFieldPositions(_ playerID: UUID, except keptPosition: FieldPosition? = nil) {
        for position in FieldPosition.allCases {
            guard position != keptPosition else { continue }

            if viewModel.lineup[position]?.id == playerID {
                viewModel.updateFieldPosition(position, playerID: nil)
            }
        }
    }

    // Returns active players not currently assigned to any defensive position.
    private func benchPlayers() -> [Player] {
        let assignedIDs = Set(viewModel.lineup.values.map { $0.id })
        return sortedActivePlayers.filter { !assignedIDs.contains($0.id) }
    }

    // MARK: - Field / Lineup Sections
    // Reusable field preview so compact and iPad layouts share the same behavior.
    private var fieldPreviewContent: some View {
        FieldPreviewView(
            lineup: viewModel.lineup,
            showRatings: viewModel.showRatingsOnField,
            showFullNameAndNumber: viewModel.showFullNameAndNumber,
            onPositionTap: { position in
                // Store the tapped position so the picker knows what to update.
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
                // Removes any player currently assigned to this position.
                Button("Unassigned") {
                    updateAssignedLineupPosition(selectedFieldViewPosition, playerID: nil)
                }

                // Assign any eligible active player to the selected position.
                ForEach(sortedActivePlayers) { player in
                    Button(PlayerDisplayHelper.displayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber)) {
                        updateAssignedLineupPosition(selectedFieldViewPosition, playerID: player.id)
                    }
                }
            }

            Button("Cancel", role: .cancel) { }
        }
    }

    // Reusable assigned-lineup table so compact and iPad layouts share the same picker logic.
    private var assignedLineupContent: some View {
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

// MARK: - Lineup Actions View
// Action button group for lineup generation and inning management.
struct LineupActionsView: View {
    // Shared lineup state and lineup generation methods.
    @ObservedObject var viewModel: LineupViewModel

    // Vertical stack of assignment automation and reset actions.
    var body: some View {
        VStack(spacing: 10) {
            // Automatically generate or fill defensive assignments.
            Button {
                viewModel.assignLineup()
            } label: {
                Label(viewModel.fallBallEnabled ? "Generate Fall Ball Lineups" : "Auto-Fill Positions", systemImage: "sparkles")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Copies the current inning lineup into every inning.
            Button {
                viewModel.setCurrentLineupForAllInnings()
            } label: {
                Label("Use This Lineup for All Innings", systemImage: "square.stack.3d.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            // Destructive reset actions for inning cleanup.
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


// MARK: - Assigned Lineup View
// Table-based field assignment editor.
// Provides a compact lineup management view using picker controls for every position.
struct AssignedLineupView: View {
    // Current field assignments keyed by defensive position.
    let lineup: [FieldPosition: Player]
    // Available players shown in each assignment picker.
    let sortedPlayers: [Player]
    // Callback fired whenever a picker changes assignment.
    let onUpdate: (FieldPosition, UUID?) -> Void
    // Provides the display label for each defensive position.
    let labelProvider: (FieldPosition) -> String
    // Provides the player display text used in picker menus.
    let displayLabel: (Player) -> String
    // Provides the formatted position rating label shown beside assigned players.
    let ratingLabel: (Player, FieldPosition) -> String

    // One editable row per defensive position.
    var body: some View {
        ForEach(FieldPosition.allCases) { position in
            // Position label, assignment picker, and optional rating display.
            HStack {
                Text(labelProvider(position))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(width: 64, alignment: .leading)

                Picker("", selection: Binding(
                    get: { lineup[position]?.id },
                    set: { newPlayerID in
                        // Notify the parent view about assignment changes.
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
                    // Show the assigned player's rating for this defensive position.
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

