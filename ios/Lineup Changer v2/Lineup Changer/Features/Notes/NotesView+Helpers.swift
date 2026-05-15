// Created by Rich Morris on 5/5/26.
// Lineup Changer
// NotesView+Helpers.swift
//
//
//
import SwiftUI
import MessageUI

// MARK: - Notes View Helpers
extension NotesView {
    // MARK: - Section Header Styling
    // Shared styling helper for note section headers.
    func notesSectionHeader(_ title: String) -> some View {
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
    func validRecipients(from numbers: [String]) -> [String] {
        Array(Set(numbers.map { phoneDigits($0) }.filter { $0.count == 10 })).sorted()
    }

    // Validates recipients and device capability before presenting the message composer.
    func presentMessageComposer(recipients: [String], body: String) {
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
    var preGameTextMessage: String {
        """
        Pre Game Notes:
        \(viewModel.preGameNotes)
        """
    }

    // Text body used when sharing post-game notes.
    var postGameTextMessage: String {
        """
        Post Game Notes:
        \(viewModel.postGameNotes)
        """
    }

    // Text body used when sharing coach-only notes.
    var coachesTextMessage: String {
        """
        Coaches Notes:
        \(viewModel.coachNotes)
        """
    }

    // MARK: - Note Bindings
    // Binding used by the first text editor for the selected notes group.
    var preGameNotesBinding: Binding<String> {
        switch selectedNotesGroup {
        case .players:
            return $viewModel.preGameNotes
        case .coaches:
            return $viewModel.coachNotes
        }
    }

    // Binding used by the second text editor in player notes mode.
    var postGameNotesBinding: Binding<String> {
        switch selectedNotesGroup {
        case .players:
            return $viewModel.postGameNotes
        case .coaches:
            // Coach mode has no second editor, so this binding is intentionally unused.
            return .constant("")
        }
    }
}

