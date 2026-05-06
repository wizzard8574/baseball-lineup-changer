// Created by Rich Morris on 5/5/26.
// Lineup Changer
// NotesView.swift
//
//
//
// NotesView.swift contains the Notes tab UI.
// It lets coaches write pre-game, post-game, and coach-only notes, clear notes,
// and send those notes by text message to valid player or coach phone numbers.
import SwiftUI
import Foundation
import MessageUI

// MARK: - Notes Group
// Segmented-control options for switching between player/team notes and coach notes.
private enum NotesGroup: String, CaseIterable, Identifiable {
    // Player notes include pre-game and post-game team notes.
    case players = "Players"
    // Coach notes are shared only with coach recipients.
    case coaches = "Coaches"

    // Allows NotesGroup to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }
}

// MARK: - Text Message Draft
// Lightweight value used to present MessageComposerView with recipients and body text.
private struct TextMessageDraft: Identifiable {
    // Unique ID lets this value drive a SwiftUI item-based sheet.
    let id = UUID()
    // Normalized 10-digit phone numbers passed to the message composer.
    let recipients: [String]
    // Note text pre-filled into the outgoing message.
    let body: String
}

// MARK: - Notes View
// Main Notes tab screen.
struct NotesView: View {
    // Shared app state containing players, coaches, and persisted notes.
    @ObservedObject var viewModel: LineupViewModel
    // Tracks whether a note editor currently has keyboard focus.
    @FocusState private var isEditing: Bool
    // Current segmented-control selection.
    @State private var selectedNotesGroup: NotesGroup = .players
    // When set, presents the native message composer sheet.
    @State private var messageDraft: TextMessageDraft?
    // When set, shows an alert explaining why texting cannot start.
    @State private var messageAlertText: String?
    // Coach notes are persisted in viewModel.coachNotes.
    
    // MARK: - Recipient Lists
    // Combines player and coach cell numbers before recipient validation.
    private var allContactNumbers: [String] {
        viewModel.players.map(\.cell) + viewModel.coaches.map(\.cell)
    }

    // Valid text recipients for player/team notes.
    private var allTeamRecipients: [String] {
        validRecipients(from: allContactNumbers)
    }

    // Valid text recipients for coach-only notes.
    private var coachRecipients: [String] {
        validRecipients(from: viewModel.coaches.map(\.cell))
    }
    
    // MARK: - Sorted Player Data
    // Players sorted by jersey number first, then alphabetically by name.
    private var sortedPlayers: [Player] {
        viewModel.players.sorted { lhs, rhs in
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
    
    // MARK: - Body
    // Main notes layout with team picker, notes group picker, editors, and text actions.
    var body: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed app background.
                AppSportsBackground()

                GeometryReader { geo in
                // GeometryReader lets the text editors split available vertical space.
                VStack(spacing: 8) {
                    // Team picker controls which team's notes are being edited.
                    TeamPickerView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .padding(.horizontal)

                    // Switches between player/team notes and coach-only notes.
                    Picker("Notes Group", selection: $selectedNotesGroup) {
                        ForEach(NotesGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Player notes show separate pre-game and post-game editors.
                    if selectedNotesGroup == .players {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // Section title for pre-game notes.
                                notesSectionHeader("Pre Game Notes")

                                Spacer()

                                // Text pre-game notes to all valid team recipients.
                                Button {
                                    presentMessageComposer(recipients: allTeamRecipients, body: preGameTextMessage)
                                } label: {
                                    Label("Text Team", systemImage: "message.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(allTeamRecipients.isEmpty)

                                // Clear saved pre-game notes.
                                Button {
                                    viewModel.preGameNotes = ""
                                } label: {
                                    Label("Clear", systemImage: "xmark.circle")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.secondary)
                                .disabled(viewModel.preGameNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            // Editable pre-game notes field.
                            TextEditor(text: preGameNotesBinding)
                                .focused($isEditing)
                                .padding(6)
                                .frame(height: max(140, (geo.size.height - 170) / 2))
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // Section title for post-game notes.
                                notesSectionHeader("Post Game Notes")

                                Spacer()

                                // Text post-game notes to all valid team recipients.
                                Button {
                                    presentMessageComposer(recipients: allTeamRecipients, body: postGameTextMessage)
                                } label: {
                                    Label("Text Team", systemImage: "message.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(allTeamRecipients.isEmpty)

                                // Clear saved post-game notes.
                                Button {
                                    viewModel.postGameNotes = ""
                                } label: {
                                    Label("Clear", systemImage: "xmark.circle")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.secondary)
                                .disabled(viewModel.postGameNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            // Editable post-game notes field.
                            TextEditor(text: postGameNotesBinding)
                                .focused($isEditing)
                                .padding(6)
                                .frame(height: max(140, (geo.size.height - 170) / 2))
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }
                    } else {
                        // Coach notes show a single editor and message only coach recipients.
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // Section title for coach notes.
                                notesSectionHeader("Coaches Notes")

                                Spacer()

                                // Text coach notes to valid coach recipients only.
                                Button {
                                    presentMessageComposer(recipients: coachRecipients, body: coachesTextMessage)
                                } label: {
                                    Label("Text Coaches", systemImage: "message.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(coachRecipients.isEmpty)

                                // Clear saved coach notes.
                                Button {
                                    viewModel.coachNotes = ""
                                } label: {
                                    Label("Clear", systemImage: "xmark.circle")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.secondary)
                                .disabled(viewModel.coachNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            // Editable coach-only notes field.
                            TextEditor(text: $viewModel.coachNotes)
                                .focused($isEditing)
                                .padding(6)
                                .frame(height: max(240, geo.size.height - 120))
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        // Decorative notes icon used in the custom navigation title.
                        Image(systemName: "note.text")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                        Text("Notes")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                }

                // Keyboard toolbar button for dismissing the active text editor.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isEditing = false
                    }
                }
            }
            // Presents the native message composer with the prepared draft.
            .sheet(item: $messageDraft) { draft in
                MessageComposerView(recipients: draft.recipients, body: draft.body)
            }
            // Shows texting errors such as missing recipients or unsupported devices.
            .alert("Unable to Text", isPresented: Binding(
                get: { messageAlertText != nil },
                set: { if !$0 { messageAlertText = nil } }
            )) {
                Button("OK", role: .cancel) { messageAlertText = nil }
            } message: {
                Text(messageAlertText ?? "")
            }
        }
    }

    // MARK: - Section Header Styling
    // Shared styling helper for note section headers.
    private func notesSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .textCase(nil)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.black.opacity(0.22), in: Capsule())
    }

    // MARK: - Messaging Helpers
    // Normalizes, filters, de-duplicates, and sorts phone numbers for texting.
    private func validRecipients(from numbers: [String]) -> [String] {
        Array(Set(numbers.map { phoneDigits($0) }.filter { $0.count == 10 })).sorted()
    }

    // Validates recipients and device capability before presenting the message composer.
    private func presentMessageComposer(recipients: [String], body: String) {
        // Require at least one valid 10-digit phone number.
        guard !recipients.isEmpty else {
            messageAlertText = "No valid 10-digit cell numbers were found."
            return
        }

        // Some devices, such as simulators or iPads without SMS support, cannot send texts.
        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        // Setting the draft triggers the item-based sheet presentation.
        messageDraft = TextMessageDraft(recipients: recipients, body: body)
    }

    // MARK: - Message Bodies
    // Text body used when sharing pre-game notes.
    private var preGameTextMessage: String {
        """
        Pre Game Notes:
        \(viewModel.preGameNotes)
        """
    }

    // Text body used when sharing post-game notes.
    private var postGameTextMessage: String {
        """
        Post Game Notes:
        \(viewModel.postGameNotes)
        """
    }

    // Text body used when sharing coach-only notes.
    private var coachesTextMessage: String {
        """
        Coaches Notes:
        \(viewModel.coachNotes)
        """
    }

    // MARK: - Note Bindings
    // Binding used by the first text editor for the selected notes group.
    private var preGameNotesBinding: Binding<String> {
        switch selectedNotesGroup {
        case .players:
            return $viewModel.preGameNotes
        case .coaches:
            return $viewModel.coachNotes
        }
    }

    // Binding used by the second text editor in player notes mode.
    private var postGameNotesBinding: Binding<String> {
        switch selectedNotesGroup {
        case .players:
            return $viewModel.postGameNotes
        case .coaches:
            // Coach mode has no second editor, so this binding is intentionally unused.
            return .constant("")
        }
    }
}
