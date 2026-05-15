// Created by Rich Morris on 5/5/26.
// Lineup Changer
// CoachDetailView.swift
//
//
//
// This file contains the SwiftUI detail view used to display and edit coach information.
import SwiftUI
import MessageUI

// MARK: - Coach Detail Supporting Types
// Tracks which text field is currently focused in the coach detail form.
// This is used by the keyboard toolbar's Done button to dismiss the keyboard.
enum CoachDetailFocusedField: Hashable {
    case name
    case number
    case role
    case cell
}

// Available coach roles in the app.
// The raw value is what is stored on the Coach model and shown in the UI.
enum CoachRoleOption: String, CaseIterable, Identifiable {
    case headCoach = "Head Coach"
    case assistantCoach = "Assistant Coach"

    // Allows the enum to be used directly in SwiftUI ForEach views.
    var id: String { rawValue }
}

// MARK: - Coach Detail View
// Detail screen for viewing and editing a coach.
// Edits are staged in local @State properties and written back to the view model
// when the user taps Save, submits a field, or taps Done on the keyboard toolbar.
struct CoachDetailView: View {
    // Shared app state that owns the coaches array and persistence/update methods.
    @ObservedObject var viewModel: LineupViewModel
    // The coach selected when this detail view was opened.
    let coach: Coach

    // Local editable copies of coach fields. These keep form editing separate from
    // the saved model until saveCoachInfo() writes the values back.
    @State var editedName = ""
    @State var editedNumber = ""
    @State var selectedRole: CoachRoleOption = .assistantCoach
    @State var editedCellNumber = ""
    // Controls presentation of the in-app Messages composer.
    @State var isShowingMessageComposer = false
    // When set, an alert is shown explaining why texting cannot be started.
    @State var messageAlertText: String?
    // Tracks keyboard focus for the form's editable fields.
    @FocusState var focusedField: CoachDetailFocusedField?
    // Allows the Save button to close the detail screen after saving.
    @Environment(\.dismiss) var dismiss

    // Looks up the latest version of this coach from the view model.
    // This protects the screen from using stale data if the coaches array changes.
    var currentCoach: Coach? {
        viewModel.coaches.first(where: { $0.id == coach.id })
    }

    // Prevents assigning more than one Head Coach.
    // If another coach is already the Head Coach, this coach can only choose Assistant Coach.
    var availableRoleOptions: [CoachRoleOption] {
        let anotherHeadCoachExists = viewModel.coaches.contains { existingCoach in
            existingCoach.id != coach.id && existingCoach.role == CoachRoleOption.headCoach.rawValue
        }

        if anotherHeadCoachExists {
            return CoachRoleOption.allCases.filter { $0 != .headCoach }
        }

        return CoachRoleOption.allCases
    }

    // Main coach editing form.
    var body: some View {
        coachDetailScreen
    }
}
