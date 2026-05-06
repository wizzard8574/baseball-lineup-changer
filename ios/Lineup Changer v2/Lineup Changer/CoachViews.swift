// Created by Rich Morris on 5/5/26.
// Lineup Changer
// CoachViews.swift
//
//
//
// This file contains the SwiftUI views used to display and edit coach information.
// It includes the compact row shown in coach lists and the detail form used to
// update a coach's name, number, role, and cell phone contact actions.
import SwiftUI
import MessageUI

// MARK: - Coach Row

// MARK: - Coach Row View
// Displays a single coach in a list-style row.
// The row shows the coach name, optional role, optional number, and a reusable
// phone contact menu for calling/texting the saved cell number.
struct CoachRowView: View {
    // Coach model rendered by this row.
    let coach: Coach

    // Main row layout.
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name and role are shown on the same line so the role reads as a subtitle.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(coach.name)
                    .font(.headline)

                if !coach.role.isEmpty {
                    Text("- \(coach.role)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Only show the coach number when one has been entered.
            if !coach.number.isEmpty {
                Text("#\(coach.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Shared call/text menu for the coach's cell number.
            PhoneContactMenu(number: coach.cell)
                .font(.caption)
        }
    }
}

// MARK: - Coach Detail

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
    @State private var editedName = ""
    @State private var editedNumber = ""
    @State private var selectedRole: CoachRoleOption = .assistantCoach
    @State private var editedCellNumber = ""
    // Controls presentation of the in-app Messages composer.
    @State private var isShowingMessageComposer = false
    // When set, an alert is shown explaining why texting cannot be started.
    @State private var messageAlertText: String?
    // Tracks keyboard focus for the form's editable fields.
    @FocusState private var focusedField: CoachDetailFocusedField?
    // Allows the Save button to close the detail screen after saving.
    @Environment(\.dismiss) private var dismiss

    // Looks up the latest version of this coach from the view model.
    // This protects the screen from using stale data if the coaches array changes.
    private var currentCoach: Coach? {
        viewModel.coaches.first(where: { $0.id == coach.id })
    }

    // Prevents assigning more than one Head Coach.
    // If another coach is already the Head Coach, this coach can only choose Assistant Coach.
    private var availableRoleOptions: [CoachRoleOption] {
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
        Form {
            Section("Coach") {
                // Coach name field.
                TextField("Name", text: $editedName)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit {
                        saveCoachInfo()
                        focusedField = nil
                    }

                // Coach number field. Uses the number pad because this is expected to be numeric.
                TextField("Number", text: $editedNumber)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .number)
                    .submitLabel(.done)
                    .onSubmit {
                        saveCoachInfo()
                        focusedField = nil
                    }
                
                // Role picker. Options are filtered so only one coach can be Head Coach.
                Picker("Role", selection: $selectedRole) {
                    ForEach(availableRoleOptions) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.menu)

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
                            saveCoachInfo()
                            focusedField = nil
                        }

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

                // Inline validation feedback for invalid cell numbers.
                if !isPhoneNumberValidOrEmpty(editedCellNumber) {
                    Text("Cell # must contain exactly 10 digits.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
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
            editedName = currentCoach?.name ?? coach.name
            editedNumber = currentCoach?.number ?? coach.number
            selectedRole = CoachRoleOption(rawValue: currentCoach?.role ?? coach.role) ?? .assistantCoach
            // If the saved role is no longer allowed, fall back to Assistant Coach.
            if !availableRoleOptions.contains(selectedRole) {
                selectedRole = .assistantCoach
            }
            editedCellNumber = currentCoach?.cell ?? coach.cell
        }
    }

    // MARK: - Private Actions
    // Validates the cell number and device capability before showing the message composer.
    private func presentMessageComposer() {
        let recipient = phoneDigits(editedCellNumber)

        // Require a complete 10-digit number before texting.
        guard recipient.count == 10 else {
            messageAlertText = "This coach does not have a valid 10-digit cell number."
            return
        }

        // Some devices, such as simulators or iPads without SMS support, cannot send texts.
        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        isShowingMessageComposer = true
    }

    // Writes valid form values back to the view model.
    // The view model methods are responsible for updating stored coach data.
    private func saveCoachInfo() {
        // Do not save while the cell number is invalid.
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        viewModel.updateCoachName(coachID: coach.id, newName: editedName)
        viewModel.updateCoachNumber(coachID: coach.id, newNumber: editedNumber)
        viewModel.updateCoachRole(coachID: coach.id, newRole: selectedRole.rawValue)
        viewModel.updateCoachCell(coachID: coach.id, newCell: editedCellNumber)
    }
}
