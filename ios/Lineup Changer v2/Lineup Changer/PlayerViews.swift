// Created by Rich Morris on 5/5/26.
// Lineup Changer
// PlayerViews.swift
//
//
//
// PlayerViews.swift contains player display helpers, roster row UI, and player detail editing UI.
// It supports player labels, status styling, phone contact actions, notes, speed rating,
// position ratings, duplicate-number validation, and player profile persistence.
import SwiftUI
import MessageUI

// MARK: - Player Display Helpers

// Shared formatting helpers used by player rows, lineup views, field assignment views, and PDFs.

struct PlayerDisplayHelper {
    // Builds the main player label and optionally appends guest status text.
    static func displayLabel(for player: Player, showFullNameAndNumber: Bool, includeStatus: Bool = true) -> String {
        // Start with the display mode-specific name/number label.
        let baseLabel = baseDisplayLabel(for: player, showFullNameAndNumber: showFullNameAndNumber)
        return includeStatus && player.status == .guest ? "\(baseLabel) (Guest)" : baseLabel
    }

    // Builds the name/number portion of a player label without status text.
    static func baseDisplayLabel(for player: Player, showFullNameAndNumber: Bool) -> String {
        // Split the name so compact mode can use the first name only.
        let nameParts = player.name.split(separator: " ").map(String.init)

        // Full mode shows complete name and optional jersey number.
        if showFullNameAndNumber {
            return player.number.isEmpty ? player.name : "#\(player.number) \(player.name)"
        } else {
            let firstName = nameParts.first ?? player.name
            return player.number.isEmpty ? firstName : "#\(player.number) \(firstName)"
        }
    }

    // Returns short inline status text for non-active players.
    static func inlineStatusText(for player: Player) -> String? {
        switch player.status {
        case .active:
            return nil
        case .guest:
            return "(Guest)"
        case .injured:
            return "(Injured)"
        case .unavailable:
            return "(Unavailable)"
        }
    }

    // Chooses a visual color for inline status text.
    static func inlineStatusColor(for player: Player) -> Color {
        switch player.status {
        case .guest, .injured:
            return .red
        case .unavailable:
            return .orange
        case .active:
            return .secondary
        }
    }

    // Creates a compact summary of all rated defensive positions.
    static func positionSummary(for player: Player) -> String {
        // Preserve FieldPosition order so summaries are predictable.
        FieldPosition.allCases
            .compactMap { position in
                guard let rating = player.positionRatings[position] else { return nil }
                return "\(position.rawValue): \(rating)"
            }
            .joined(separator: " • ")
    }

    // Converts each field position into the common baseball scorebook numbering label.
    static func assignedLineupLabel(for position: FieldPosition) -> String {
        switch position {
        case .pitcher:
            return "P - 1"
        case .catcher:
            return "C - 2"
        case .firstBase:
            return "1B - 3"
        case .secondBase:
            return "2B - 4"
        case .thirdBase:
            return "3B - 5"
        case .shortstop:
            return "SS - 6"
        case .leftField:
            return "LF - 7"
        case .centerField:
            return "CF - 8"
        case .rightField:
            return "RF - 9"
        }
    }

    // Displays the player's rating for a field position, or Manual when no rating exists.
    static func ratingLabel(for player: Player, at position: FieldPosition) -> String {
        // Manual assignments may not have a stored rating for that position.
        guard let rating = player.positionRatings[position] else { return "Manual" }
        return "Rating \(rating)"
    }
}

// MARK: - Player Row View

// Compact roster row for one player.
// Shows the player label, status, phone contact menu, and defensive position summary.

struct PlayerRowView: View {
    // Player model rendered by this row.
    let player: Player
    // Shared display settings used to format the player label.
    let viewModel: LineupViewModel

    // Main row layout.
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Player label and optional inline status sit on the first line.
            HStack(spacing: 4) {
                // Use base label here because inline status is rendered separately.
                Text(PlayerDisplayHelper.baseDisplayLabel(for: player, showFullNameAndNumber: viewModel.showFullNameAndNumber))
                    .font(.headline)

                // Active players omit status text to keep the row clean.
                if let statusText = PlayerDisplayHelper.inlineStatusText(for: player) {
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(PlayerDisplayHelper.inlineStatusColor(for: player))
                }
            }

            // Reusable call/text menu for the player's cell number.
            PhoneContactMenu(number: player.cell)
                .font(.caption)

            // Show either a no-positions placeholder or a compact rating summary.
            if player.positionRatings.isEmpty {
                Text("No positions added")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(PlayerDisplayHelper.positionSummary(for: player))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Player Detail Supporting Types

// Tracks which field is focused in the player detail form.
// Used by the keyboard toolbar to save and dismiss editing.

private enum PlayerDetailFocusedField: Hashable {
    case name
    case number
    case cell
    case notes
}

// MARK: - Player Detail View
// Detail screen for viewing and editing a player profile.
// Edits are staged in local @State properties and saved back to the view model.
struct PlayerDetailView: View {
    // Shared app state that owns player updates, ratings, and persistence.
    @ObservedObject var viewModel: LineupViewModel
    // Player selected when this detail view was opened.
    let player: Player
    
    // Local editable copies of player profile fields.
    @State private var editedName: String = ""
    @State private var editedNumber: String = ""
    @State private var editedCellNumber: String = ""
    // Local player status and rating selections.
    @State private var isGuestPlayer = false
    @State private var selectedSpeedRating: Int = 1
    @State private var selectedPosition: FieldPosition = .firstBase
    @State private var selectedRating: Int = 1
    // Local notes and messaging state.
    @State private var editedNotes: String = ""
    @State private var isShowingMessageComposer = false
    @State private var messageAlertText: String?
    @State private var duplicateNumberAlertText: String?
    // Tracks keyboard focus for editable fields.
    @FocusState private var focusedField: PlayerDetailFocusedField?
    // Allows the Save button to close the detail screen.
    @Environment(\.dismiss) private var dismiss
    
    // Looks up the latest version of this player from the view model.
    private var currentPlayer: Player? {
        viewModel.players.first(where: { $0.id == player.id })
    }

    // Positions that do not already have a rating for this player.
    private var availablePositions: [FieldPosition] {
        FieldPosition.allCases.filter { position in
            !(currentPlayer?.positionRatings.keys.contains(position) ?? false)
        }
    }
    
    // MARK: - Body
    // Main player editing form.
    var body: some View {
        Form {
            Section("Player") {
                // Player name field.
                TextField("Name", text: $editedName)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit {
                        savePlayerInfo()
                        focusedField = nil
                    }
                
                // Jersey number field.
                TextField("Number", text: $editedNumber)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .number)
                    .submitLabel(.done)
                    .onSubmit {
                        savePlayerInfo()
                        focusedField = nil
                    }
                
                // Cell number field plus quick call/text actions when the number is valid.
                HStack {
                    TextField("Cell #", text: $editedCellNumber)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .cell)
                        .submitLabel(.done)
                        // Normalize phone input as the user types.
                        .onChange(of: editedCellNumber) { oldValue, newValue in
                            editedCellNumber = normalizedPhoneInput(oldValue: oldValue, newValue: newValue)
                        }
                        .onSubmit {
                            savePlayerInfo()
                            focusedField = nil
                        }

                    // Show contact shortcuts only for complete 10-digit numbers.
                    if phoneDigits(editedCellNumber).count == 10 {
                        // Show a call shortcut when a phone URL can be created.
                        if let callURL = phoneCallURL(for: editedCellNumber) {
                            Link(destination: callURL) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        // Show a text shortcut that presents MessageComposerView.
                        Button {
                            presentMessageComposer()
                        } label: {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Guest players can share jersey numbers with non-guest players.
                Toggle("Guest", isOn: $isGuestPlayer)
                
                // Inline validation feedback for invalid cell numbers.
                if !isPhoneNumberValidOrEmpty(editedCellNumber) {
                    Text("Cell # must contain exactly 10 digits.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
            }
            
            // Freeform player notes.
            Section("Notes") {
                TextEditor(text: $editedNotes)
                    .focused($focusedField, equals: .notes)
                    .frame(minHeight: 100)
            }
            
            // Simple speed rating used by lineup warning logic.
            Section("Steal Ability") {
                Picker("Steal Ability", selection: $selectedSpeedRating) {
                    Label("Steal", systemImage: "figure.run").tag(1)
                    Label("No Steal", systemImage: "hand.raised.fill").tag(2)
                }
                .pickerStyle(.segmented)
            }
            
            // Adds a new defensive position rating for this player.
            Section("Add or Update Position") {
                // Once every position has a rating, no new positions can be added.
                if availablePositions.isEmpty {
                    Text("All positions already assigned.")
                        .foregroundStyle(.secondary)
                } else {
                    // Choose an unrated position to add.
                    Picker("Position", selection: $selectedPosition) {
                        ForEach(availablePositions) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                }

                // Rating controls are shown only when a position is available to add.
                if !availablePositions.isEmpty {
                    // Lower number means stronger rating.
                    Picker("Rating", selection: $selectedRating) {
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating)").tag(rating)
                        }
                    }

                    // Save the selected position rating and advance to the next available position.
                    Button("Save Position") {
                        viewModel.setRating(playerID: player.id, position: selectedPosition, rating: selectedRating)
                        selectFirstAvailablePosition()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Existing defensive ratings can be edited or removed here.
            Section("Current Positions") {
                // Empty-state message before any position ratings are stored.
                if let currentPlayer, currentPlayer.positionRatings.isEmpty {
                    Text("No positions added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    // Display ratings in the standard FieldPosition order.
                    ForEach(FieldPosition.allCases) { position in
                        if let rating = currentPlayer?.positionRatings[position] {
                            // Position label and editable segmented rating picker.
                            HStack {
                                Text(position.rawValue)
                                    .fontWeight(.semibold)
                                Spacer()
                                Picker("Rating", selection: Binding(
                                    get: { rating },
                                    set: { newRating in
                                        viewModel.setRating(playerID: player.id, position: position, rating: newRating)
                                    }
                                )) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Text("\(rating)").tag(rating)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            // Swipe to remove a position rating.
                            .swipeActions {
                                Button("Remove", role: .destructive) {
                                    viewModel.removePosition(playerID: player.id, position: position)
                                }
                            }
                        }
                    }
                }
            }
            
            // Explains how defensive ratings affect lineup assignment.
            Section("Scale") {
                Text("1 = High, 5 = Low. A player is only considered for positions listed here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(currentPlayer?.name ?? player.name)
        .toolbar {
            // Saves changes and exits when there is no duplicate-number warning.
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    savePlayerInfo()
                    if duplicateNumberAlertText == nil {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isPhoneNumberValidOrEmpty(editedCellNumber))
            }
            // Keyboard accessory button for saving edits and dismissing the keyboard.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    savePlayerInfo()
                    focusedField = nil
                }
            }
        }
        // Presents the native message composer wrapper when texting is available.
        .sheet(isPresented: $isShowingMessageComposer) {
            MessageComposerView(recipients: [phoneDigits(editedCellNumber)], body: "")
        }
        // Displays texting-related errors.
        .alert("Unable to Text", isPresented: Binding(
            get: { messageAlertText != nil },
            set: { if !$0 { messageAlertText = nil } }
        )) {
            Button("OK", role: .cancel) { messageAlertText = nil }
        } message: {
            Text(messageAlertText ?? "")
        }
        // Displays duplicate number validation errors for non-guest players.
        .alert("Duplicate Player Number", isPresented: Binding(
            get: { duplicateNumberAlertText != nil },
            set: { if !$0 { duplicateNumberAlertText = nil } }
        )) {
            Button("OK", role: .cancel) { duplicateNumberAlertText = nil }
        } message: {
            Text(duplicateNumberAlertText ?? "")
        }
        // Populate the form with the latest saved player values when the screen opens.
        .onAppear {
            editedName = currentPlayer?.name ?? player.name
            editedNumber = currentPlayer?.number ?? player.number
            editedCellNumber = currentPlayer?.cell ?? player.cell
            isGuestPlayer = (currentPlayer?.status ?? player.status) == .guest
            selectedSpeedRating = currentPlayer?.speedRating ?? player.speedRating
            editedNotes = currentPlayer?.notes ?? player.notes

            // Select an initial position for the Add Position picker.
            selectFirstAvailablePosition()
        }
    }
    
    // MARK: - Private Actions
    // Validates the cell number and device capability before showing the message composer.
    private func presentMessageComposer() {
        let recipient = phoneDigits(editedCellNumber)

        // Require a complete 10-digit number before texting.
        guard recipient.count == 10 else {
            messageAlertText = "This player does not have a valid 10-digit cell number."
            return
        }

        // Some devices, such as simulators or iPads without SMS support, cannot send texts.
        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        isShowingMessageComposer = true
    }

    // Selects the first unrated position so the add-position picker always has a valid value.
    private func selectFirstAvailablePosition() {
        if let first = availablePositions.first {
            selectedPosition = first
        }
    }

    // Checks whether another non-guest player already uses this jersey number.
    private func isDuplicateNonGuestNumber(_ number: String) -> Bool {
        // Blank jersey numbers are allowed and are not treated as duplicates.
        let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNumber.isEmpty else { return false }

        // Guests are allowed to reuse numbers, so only non-guest players are compared.
        return viewModel.players.contains { otherPlayer in
            otherPlayer.id != player.id
            && otherPlayer.status != .guest
            && otherPlayer.number.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedNumber
        }
    }

    // Writes valid form values back to the view model.
    private func savePlayerInfo() {
        // Do not save while the cell number is invalid.
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        // Prevent duplicate jersey numbers for non-guest players.
        if !isGuestPlayer, isDuplicateNonGuestNumber(editedNumber) {
            duplicateNumberAlertText = "A non-guest player with number #\(editedNumber) already exists. Check Guest if this is a guest player using the same number."
            return
        }
        // Persist all edited player fields through view-model update methods.
        viewModel.renamePlayer(playerID: player.id, newName: editedName)
        viewModel.updatePlayerNumber(playerID: player.id, newNumber: editedNumber)
        viewModel.updatePlayerCell(playerID: player.id, newCell: editedCellNumber)
        viewModel.updatePlayerSpeed(playerID: player.id, speedRating: selectedSpeedRating)
        viewModel.updatePlayerNotes(playerID: player.id, notes: editedNotes)
        viewModel.setPlayerStatus(playerID: player.id, status: isGuestPlayer ? .guest : .active)
    }
    
}
