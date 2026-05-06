//
//  CoachViews.swift
//  Lineup Changer
//

import SwiftUI
import MessageUI

// MARK: - Coach Row
struct CoachRowView: View {
    let coach: Coach

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(coach.name)
                    .font(.headline)

                if !coach.role.isEmpty {
                    Text("- \(coach.role)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !coach.number.isEmpty {
                Text("#\(coach.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PhoneContactMenu(number: coach.cell)
                .font(.caption)
        }
    }
}

// MARK: - Coach Detail

enum CoachDetailFocusedField: Hashable {
    case name
    case number
    case role
    case cell
}

enum CoachRoleOption: String, CaseIterable, Identifiable {
    case headCoach = "Head Coach"
    case assistantCoach = "Assistant Coach"

    var id: String { rawValue }
}

struct CoachDetailView: View {
    @ObservedObject var viewModel: LineupViewModel
    let coach: Coach

    @State private var editedName = ""
    @State private var editedNumber = ""
    @State private var selectedRole: CoachRoleOption = .assistantCoach
    @State private var editedCellNumber = ""
    @State private var isShowingMessageComposer = false
    @State private var messageAlertText: String?
    @FocusState private var focusedField: CoachDetailFocusedField?
    @Environment(\.dismiss) private var dismiss

    private var currentCoach: Coach? {
        viewModel.coaches.first(where: { $0.id == coach.id })
    }

    private var availableRoleOptions: [CoachRoleOption] {
        let anotherHeadCoachExists = viewModel.coaches.contains { existingCoach in
            existingCoach.id != coach.id && existingCoach.role == CoachRoleOption.headCoach.rawValue
        }

        if anotherHeadCoachExists {
            return CoachRoleOption.allCases.filter { $0 != .headCoach }
        }

        return CoachRoleOption.allCases
    }

    var body: some View {
        Form {
            Section("Coach") {
                TextField("Name", text: $editedName)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit {
                        saveCoachInfo()
                        focusedField = nil
                    }

                TextField("Number", text: $editedNumber)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .number)
                    .submitLabel(.done)
                    .onSubmit {
                        saveCoachInfo()
                        focusedField = nil
                    }
                
                Picker("Role", selection: $selectedRole) {
                    ForEach(availableRoleOptions) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    TextField("Cell #", text: $editedCellNumber)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .cell)
                        .submitLabel(.done)
                        .onChange(of: editedCellNumber) { oldValue, newValue in
                            editedCellNumber = normalizedPhoneInput(oldValue: oldValue, newValue: newValue)
                        }
                        .onSubmit {
                            saveCoachInfo()
                            focusedField = nil
                        }

                    if phoneDigits(editedCellNumber).count == 10 {
                        if let callURL = phoneCallURL(for: editedCellNumber) {
                            Link(destination: callURL) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.blue)
                            }
                        }

                        Button {
                            presentMessageComposer()
                        } label: {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !isPhoneNumberValidOrEmpty(editedCellNumber) {
                    Text("Cell # must contain exactly 10 digits.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(currentCoach?.name ?? coach.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveCoachInfo()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isPhoneNumberValidOrEmpty(editedCellNumber))
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    saveCoachInfo()
                    focusedField = nil
                }
            }
        }
        .sheet(isPresented: $isShowingMessageComposer) {
            MessageComposerView(recipients: [phoneDigits(editedCellNumber)], body: "")
        }
        .alert("Unable to Text", isPresented: Binding(
            get: { messageAlertText != nil },
            set: { if !$0 { messageAlertText = nil } }
        )) {
            Button("OK", role: .cancel) { messageAlertText = nil }
        } message: {
            Text(messageAlertText ?? "")
        }
        .onAppear {
            editedName = currentCoach?.name ?? coach.name
            editedNumber = currentCoach?.number ?? coach.number
            selectedRole = CoachRoleOption(rawValue: currentCoach?.role ?? coach.role) ?? .assistantCoach
            if !availableRoleOptions.contains(selectedRole) {
                selectedRole = .assistantCoach
            }
            editedCellNumber = currentCoach?.cell ?? coach.cell
        }
    }

    private func presentMessageComposer() {
        let recipient = phoneDigits(editedCellNumber)

        guard recipient.count == 10 else {
            messageAlertText = "This coach does not have a valid 10-digit cell number."
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            messageAlertText = "Text messaging is not available on this device."
            return
        }

        isShowingMessageComposer = true
    }

    private func saveCoachInfo() {
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        viewModel.updateCoachName(coachID: coach.id, newName: editedName)
        viewModel.updateCoachNumber(coachID: coach.id, newNumber: editedNumber)
        viewModel.updateCoachRole(coachID: coach.id, newRole: selectedRole.rawValue)
        viewModel.updateCoachCell(coachID: coach.id, newCell: editedCellNumber)
    }
}
