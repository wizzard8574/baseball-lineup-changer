// Created by Rich Morris on 5/5/26.
// Lineup Changer
// CoachDetailView+ScreenChrome.swift
//
//
//
import SwiftUI

// MARK: - Coach Detail Screen Chrome
extension CoachDetailView {
    var coachDetailScreen: some View {
        Form {
            coachFormSection
        }
        .navigationTitle(currentCoach?.name ?? coach.name)
        .toolbar {
            // Saves changes and exits the detail view.
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveCoachInfo()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isPhoneNumberValidOrEmpty(editedCellNumber))
            }

            // Keyboard accessory button for saving field edits and dismissing the keyboard.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    saveCoachInfo()
                    focusedField = nil
                }
            }
        }
        // Presents the native message composer wrapper when texting is available.
        .sheet(isPresented: $isShowingMessageComposer) {
            MessageComposerView(recipients: [phoneDigits(editedCellNumber)], body: "")
        }
        // Displays any texting-related error message.
        .alert("Unable to Text", isPresented: Binding(
            get: { messageAlertText != nil },
            set: { if !$0 { messageAlertText = nil } }
        )) {
            Button("OK", role: .cancel) { messageAlertText = nil }
        } message: {
            Text(messageAlertText ?? "")
        }
        // Populate the form with the latest saved coach values when the screen opens.
        .onAppear {
            loadCoachInfo()
        }
    }
}
