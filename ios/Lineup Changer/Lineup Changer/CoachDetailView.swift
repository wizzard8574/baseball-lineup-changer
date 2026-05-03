//
//  CoachDetailView.swift
//  Lineup Changer
//
//  Created by Rich Morris on 5/2/26.
//

import SwiftUI

// MARK: - Coach Detail

private enum CoachDetailFocusedField: Hashable {
    case name
    case number
    case role
    case cell
}

private enum CoachRoleOption: String, CaseIterable, Identifiable {
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

                        if let textURL = phoneTextURL(for: editedCellNumber) {
                            Link(destination: textURL) {
                                Image(systemName: "message.fill")
                                    .foregroundStyle(.green)
                            }
                        }
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

    private func saveCoachInfo() {
        guard isPhoneNumberValidOrEmpty(editedCellNumber) else { return }
        viewModel.updateCoachName(coachID: coach.id, newName: editedName)
        viewModel.updateCoachNumber(coachID: coach.id, newNumber: editedNumber)
        viewModel.updateCoachRole(coachID: coach.id, newRole: selectedRole.rawValue)
        viewModel.updateCoachCell(coachID: coach.id, newCell: editedCellNumber)
    }
}
