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
enum NotesGroup: String, CaseIterable, Identifiable {
    // Player notes include pre-game and post-game team notes.
    case players = "Players"
    // Coach notes are shared only with coach recipients.
    case coaches = "Coaches"

    // Allows NotesGroup to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }
}

// MARK: - Text Message Draft
// Lightweight value used to present MessageComposerView with recipients and body text.
struct TextMessageDraft: Identifiable {
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
    @FocusState var isEditing: Bool
    // Current segmented-control selection.
    @State var selectedNotesGroup: NotesGroup = .players
    // When set, presents the native message composer sheet.
    @State var messageDraft: TextMessageDraft?
    // When set, shows an alert explaining why texting cannot start.
    @State var messageAlertText: String?

    // MARK: - Recipient Lists
    // Combines player and coach cell numbers before recipient validation.
    var allContactNumbers: [String] {
        viewModel.players.map(\.cell) + viewModel.coaches.map(\.cell)
    }

    // Valid text recipients for player/team notes.
    var allTeamRecipients: [String] {
        validRecipients(from: allContactNumbers)
    }

    // Valid text recipients for coach-only notes.
    var coachRecipients: [String] {
        validRecipients(from: viewModel.coaches.map(\.cell))
    }

    // MARK: - Body
    var body: some View {
        notesScreen
    }
}
