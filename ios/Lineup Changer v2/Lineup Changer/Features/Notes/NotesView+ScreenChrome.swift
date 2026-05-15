// Created by Rich Morris on 5/5/26.
// Lineup Changer
// NotesView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Notes Screen Chrome
extension NotesView {
    var notesScreen: some View {
        NavigationStack {
            ZStack {
                // Shared sports-themed app background.
                AppSportsBackground()

                GeometryReader { geo in
                    notesFormContent(geometry: geo)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppToolbarTitle(title: "Notes", systemImage: "note.text")
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
}
